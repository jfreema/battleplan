// Polls domain service: owns polls and pollVotes (ARCH §6.2).
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { db } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import { Collections } from '../shared/constants.js';
import { trySend } from '../notify/service.js';

/** One choice on a poll; IDs are '0' to '9' in the order the creator set. */
export interface PollOption {
  id: string;
  text: string;
}

/** What tallying reads of a poll. */
export interface PollTally {
  voteCounts: Record<string, number>;
  voterCount: number;
}

/**
 * Counts [votes] against [options] (POLL-2): each option's votes, and how
 * many people voted. Choices that aren't options are ignored, and a vote
 * with no valid choice doesn't count as a voter.
 */
export function tallyOf(options: PollOption[], votes: { optionIds?: unknown }[]): PollTally {
  const voteCounts: Record<string, number> = Object.fromEntries(options.map((o) => [o.id, 0]));
  let voterCount = 0;
  for (const v of votes) {
    const ids = Array.isArray(v.optionIds) ? [...new Set(v.optionIds)] : [];
    const valid = ids.filter((id): id is string => typeof id === 'string' && id in voteCounts);
    if (!valid.length) continue;
    voterCount++;
    for (const id of valid) voteCounts[id]++;
  }
  return { voteCounts, voterCount };
}

function sameTally(a: PollTally, b: Partial<PollTally>): boolean {
  if (a.voterCount !== b.voterCount) return false;
  const counts = b.voteCounts ?? {};
  const keys = new Set([...Object.keys(a.voteCounts), ...Object.keys(counts)]);
  return [...keys].every((k) => a.voteCounts[k] === counts[k]);
}

/**
 * pollVotes written → the poll's counts (ARCH §6.4 trigger map). Recounts
 * in a transaction rather than adding the change, so a trigger that runs
 * twice or out of order still leaves the right numbers: with count()
 * queries, one for the voters and one per option, a read each however
 * many voted (up to 500 in a group), rather than reading every vote (ARCH
 * §10.2). The counts match [tallyOf]: choices that aren't options count
 * for nothing, and a vote with none of them isn't a voter.
 */
export async function recountPoll(pollId: string): Promise<void> {
  const pollRef = db().collection(Collections.polls).doc(pollId);
  const votes = db().collection(Collections.pollVotes).where('pollId', '==', pollId);
  await db().runTransaction(async (tx) => {
    const poll = await tx.get(pollRef);
    if (!poll.exists) return; // Deleted with its message (POLL-5).
    const options = (poll.get('options') as PollOption[] | undefined) ?? [];
    // A voter is a vote with at least one of the poll's options (up to 10).
    const ids = options.map((o) => o.id);
    const [voterCount, ...perOption] = await Promise.all([
      ids.length ? tx.get(votes.where('optionIds', 'array-contains-any', ids).count()).then((s) => s.data().count) : 0,
      ...options.map((o) => tx.get(votes.where('optionIds', 'array-contains', o.id).count()).then((s) => s.data().count)),
    ]);
    const tally: PollTally = {
      voteCounts: Object.fromEntries(options.map((o, i) => [o.id, perOption[i]])),
      voterCount,
    };
    if (sameTally(tally, poll.data() as Partial<PollTally>)) return;
    tx.update(pollRef, { voteCounts: tally.voteCounts, voterCount: tally.voterCount });
  });
}

/**
 * The result line of a "Poll closed" notification (POLL-4): the leading
 * option, or the tied ones, with their votes.
 */
export function resultPhrase(options: PollOption[], counts: Record<string, number>): string {
  const top = Math.max(0, ...options.map((o) => counts[o.id] ?? 0));
  if (top === 0) return 'No votes';
  const leaders = options.filter((o) => (counts[o.id] ?? 0) === top).map((o) => o.text);
  const votes = top === 1 ? '1 vote' : `${top} votes`;
  if (leaders.length === 1) return `${leaders[0]} (${votes})`;
  const names = leaders.length === 2 ? leaders.join(' and ') : `${leaders.slice(0, -1).join(', ')}, and ${leaders.at(-1)}`;
  return `Tie: ${names} (${votes} each)`;
}

/** "Poll closed: Saturday or Sunday? Saturday (5 votes)" (NOTIF-5). */
export function pollClosedBody(question: string, options: PollOption[], counts: Record<string, number>): string {
  return `Poll closed: ${question.trim()} ${resultPhrase(options, counts)}`;
}

/** "Alex created a poll: Saturday or Sunday?" (NOTIF-5). */
export function pollCreatedBody(authorName: string, question: string): string {
  return `${authorName.trim() || 'Someone'} created a poll: ${question.trim()}`;
}

/** Who closed a poll: a person, or null when its close time passed. */
export type Closer = { uid: string; name: string } | null;

/**
 * Closes a poll (POLL-4): stamps closedAt, so the rules stop new votes, and
 * tells everyone who voted, with the result. Closed polls never reopen, so
 * closing twice does nothing. Returns false when the poll is gone or was
 * already closed.
 */
export async function closePollNow(pollId: string, closer: Closer): Promise<boolean> {
  const ref = db().collection(Collections.polls).doc(pollId);
  const poll = await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists || snap.get('closedAt')) return null;
    tx.update(ref, { closedAt: FieldValue.serverTimestamp(), closedBy: closer?.uid ?? null });
    return snap.data()!;
  });
  if (!poll) return false;
  // Count once more, so the result includes votes the trigger hasn't
  // tallied yet; the rules refuse votes from here on.
  await recountPoll(pollId);
  const fresh = (await ref.get()).data() ?? poll;
  const voters = await db().collection(Collections.pollVotes).where('pollId', '==', pollId).select('uid').get();
  const groupId = String(poll.groupId);
  const messageId = String(poll.messageId ?? pollId);
  const question = String(poll.question ?? '');
  await trySend({
    kind: 'pollClosed',
    groupId,
    recipients: { uids: voters.docs.map((d) => String(d.get('uid'))) },
    actor: closer,
    // The poll's message, so deleting it takes these items too (CHAT-8).
    target: { type: 'message', id: messageId },
    route: `/g/${groupId}/chat/m/${messageId}`,
    params: { question },
    body: pollClosedBody(question, (fresh.options as PollOption[]) ?? [], (fresh.voteCounts as Record<string, number>) ?? {}),
    dedupeKey: `${pollId}_closed`,
  });
  return true;
}

/**
 * Closes the polls whose close time has passed (POLL-4), for the `tick`
 * job. Reads only open polls that are due, through the closedAt and
 * closesAt index (ARCH §10.2 rule 11). Returns how many closed.
 */
export async function closeDuePolls(now = Timestamp.now()): Promise<number> {
  let closed = 0;
  for (;;) {
    const due = await db()
      .collection(Collections.polls)
      .where('closedAt', '==', null)
      .where('closesAt', '<=', now)
      .orderBy('closesAt')
      .limit(100)
      .get();
    for (const p of due.docs) {
      try {
        if (await closePollNow(p.id, null)) closed++;
      } catch (e) {
        logger.error('poll_close_failed', { pollId: p.id, error: String(e) });
        return closed; // Try the rest on the next tick rather than loop on it.
      }
    }
    if (due.size < 100) return closed;
  }
}

/** Deletes a poll and its votes, after its message was deleted (POLL-5). */
export async function deletePoll(pollId: string): Promise<void> {
  await db().collection(Collections.polls).doc(pollId).delete();
  await forEachPage(db().collection(Collections.pollVotes).where('pollId', '==', pollId), (batch, vote) =>
    batch.delete(vote.ref),
  );
}
