// Polls domain service: owns polls, pollVotes, and pollPlayerVotes (ARCH §6.2).
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { HttpsError } from 'firebase-functions/v2/https';
import { randomUUID } from 'node:crypto';
import { db } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import { Collections, Limits } from '../shared/constants.js';
import { compositeId, groupMemberId } from '../shared/ids.js';
import { trySend } from '../notify/service.js';
import { joinNames } from '../players/roster.js';

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
  await db().runTransaction(async (tx) => {
    const poll = await tx.get(pollRef);
    if (!poll.exists) return; // Deleted with its message (POLL-5).
    // One vote per player (#96) counts the players' votes, and its voters
    // are the players who have one.
    const votes = db()
      .collection(poll.get('perPlayer') === true ? Collections.pollPlayerVotes : Collections.pollVotes)
      .where('pollId', '==', pollId);
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
  // On one vote per player (#96), whoever cast a player's vote hears it.
  const voters = await db()
    .collection(poll.perPlayer === true ? Collections.pollPlayerVotes : Collections.pollVotes)
    .where('pollId', '==', pollId)
    .select('uid')
    .get();
  const groupId = String(poll.groupId);
  const messageId = String(poll.messageId ?? pollId);
  const question = String(poll.question ?? '');
  await trySend({
    kind: 'pollClosed',
    groupId,
    recipients: { uids: [...new Set(voters.docs.map((d) => String(d.get('uid'))))] },
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

/** Deletes a poll and its votes, its players' too (#96), after its message was deleted (POLL-5). */
export async function deletePoll(pollId: string): Promise<void> {
  await db().collection(Collections.polls).doc(pollId).delete();
  for (const collection of [Collections.pollVotes, Collections.pollPlayerVotes]) {
    await forEachPage(db().collection(collection).where('pollId', '==', pollId), (batch, vote) => batch.delete(vote.ref));
  }
}

/** Whether a poll still takes votes (POLL-4): not closed, and not past its close time. */
export function pollIsOpen(poll: FirebaseFirestore.DocumentData, now = Timestamp.now()): boolean {
  if (poll.closedAt) return false;
  const closesAt = poll.closesAt as Timestamp | null | undefined;
  return !closesAt || now.toMillis() < closesAt.toMillis();
}

/**
 * [optionIds] as a vote on a poll with [options] (#96): each an option,
 * none twice, one at most unless [allowMultiple], in the poll's order. An
 * empty list takes the vote back. Throws invalid-argument otherwise.
 */
export function cleanChoices(optionIds: string[], options: PollOption[], allowMultiple: boolean): string[] {
  const ids = options.map((o) => o.id);
  const picked = new Set(optionIds);
  if (picked.size !== optionIds.length || optionIds.some((id) => !ids.includes(id))) {
    throw new HttpsError('invalid-argument', 'bad-choice');
  }
  if (!allowMultiple && picked.size > 1) throw new HttpsError('invalid-argument', 'one-choice');
  return ids.filter((id) => picked.has(id));
}

/** A player's vote another guardian replaced (#96): whose it was, and what it was and is. */
export interface ReplacedVote {
  /** Who had cast it. */
  uid: string;
  playerName: string;
  before: string[];
  after: string[];
}

/** The options' texts for [optionIds]: "Pizza", "Pizza and Tacos". */
export function answerOf(optionIds: string[], options: PollOption[]): string {
  return joinNames(options.filter((o) => optionIds.includes(o.id)).map((o) => o.text.trim()));
}

/**
 * What a guardian hears when another one changes their player's vote (#96):
 * "Phil D. voted Sunday for Luke on “Which day?”, replacing your vote
 * (Saturday)", "… for Luke and Alex …", or, when they took it back, "Phil
 * D. took back the vote for Luke on “Which day?” (yours was Saturday)".
 * [players] are the first names, in roster order.
 */
export function voteReplacedBody(
  actorName: string,
  question: string,
  players: string[],
  before: string,
  after: string,
): string {
  const who = actorName.trim() || 'Another guardian';
  const q = `“${question.trim()}”`;
  const names = joinNames(players);
  if (!after) return `${who} took back the vote for ${names} on ${q} (yours was ${before})`;
  return `${who} voted ${after} for ${names} on ${q}, replacing your vote (${before})`;
}

/**
 * [uid] votes for each of [votes]' players on a one-vote-per-player poll
 * (#96): `{ playerId: optionIds }`, an empty list taking that player's vote
 * back. Only players they're linked to on the poll's team, as a parent,
 * guardian, or the player themselves, while the poll is open. Each player
 * keeps one vote, `pollPlayerVotes/{pollId}_{playerId}`, with who cast it;
 * the same answer again changes nothing, so it stays the first guardian's.
 * Written in one transaction, then counted. Returns the votes it replaced
 * that another guardian had cast, so they can be told.
 */
export async function setPlayerVotes(
  pollId: string,
  uid: string,
  votes: Record<string, string[]>,
): Promise<{ poll: FirebaseFirestore.DocumentData; replaced: ReplacedVote[] }> {
  const playerIds = Object.keys(votes);
  if (!playerIds.length) throw new HttpsError('invalid-argument', 'no-players');
  if (playerIds.length > Limits.queryLimitMax) throw new HttpsError('invalid-argument', 'too-many-players');
  const pollRef = db().collection(Collections.polls).doc(pollId);
  const poll = await pollRef.get();
  if (!poll.exists) throw new HttpsError('not-found', 'poll-not-found');
  const data = poll.data()!;
  if (data.perPlayer !== true) throw new HttpsError('failed-precondition', 'not-per-player');
  const groupId = String(data.groupId);
  const options = (data.options as PollOption[] | undefined) ?? [];
  const allowMultiple = data.allowMultiple === true;
  const chosen = new Map(playerIds.map((p) => [p, cleanChoices(votes[p] ?? [], options, allowMultiple)]));
  // Their own players: a link of theirs (either relation) on this team.
  const links = await db().getAll(...playerIds.map((p) => db().collection(Collections.playerGuardians).doc(compositeId(p, uid))));
  if (links.some((l) => !l.exists || l.get('groupId') !== groupId)) {
    throw new HttpsError('permission-denied', 'not-your-player');
  }
  const players = await db().getAll(...playerIds.map((p) => db().collection(Collections.players).doc(p)));
  const nameOf = new Map(
    players.map((p) => [p.id, String(p.get('displayName') ?? '').trim().split(/\s+/)[0] || 'your player']),
  );
  const replaced = await db().runTransaction(async (tx) => {
    const [fresh, member, ...current] = await Promise.all([
      tx.get(pollRef),
      tx.get(db().collection(Collections.groupMembers).doc(groupMemberId(groupId, uid))),
      ...playerIds.map((p) => tx.get(db().collection(Collections.pollPlayerVotes).doc(compositeId(pollId, p)))),
    ]);
    if (!member.exists) throw new HttpsError('permission-denied', 'not-a-member');
    // Closed meanwhile (POLL-4): the rules would refuse a direct vote too.
    if (!fresh.exists || !pollIsOpen(fresh.data()!)) throw new HttpsError('failed-precondition', 'poll-closed');
    const out: ReplacedVote[] = [];
    playerIds.forEach((playerId, i) => {
      const before = current[i].exists ? ((current[i].get('optionIds') as string[] | undefined) ?? []) : [];
      const after = chosen.get(playerId)!;
      if (same(before, after)) return; // The same answer: theirs stays theirs.
      const castBy = current[i].exists ? String(current[i].get('uid') ?? '') : '';
      if (before.length && castBy && castBy !== uid) {
        out.push({ uid: castBy, playerName: nameOf.get(playerId)!, before, after });
      }
      const ref = current[i].ref;
      if (!after.length) {
        tx.delete(ref);
      } else {
        tx.set(ref, { pollId, groupId, playerId, optionIds: after, uid, updatedAt: FieldValue.serverTimestamp() });
      }
    });
    return out;
  });
  await recountPoll(pollId);
  return { poll: data, replaced };
}

function same(a: string[], b: string[]): boolean {
  return a.length === b.length && a.every((id) => b.includes(id));
}

/**
 * Tells each guardian whose vote for a player another guardian just
 * replaced (#96): who did it, for which players, and what it is and was.
 * Players whose votes changed alike are named together ("Luke and Alex"),
 * so siblings make one notification.
 */
export async function tellVotesReplaced(input: {
  pollId: string;
  poll: FirebaseFirestore.DocumentData;
  actor: { uid: string; name: string };
  replaced: ReplacedVote[];
}): Promise<void> {
  const options = (input.poll.options as PollOption[] | undefined) ?? [];
  const groups = new Map<string, { uid: string; players: string[]; before: string; after: string }>();
  for (const r of input.replaced) {
    const before = answerOf(r.before, options);
    const after = answerOf(r.after, options);
    const key = `${r.uid}|${before}|${after}`;
    const group = groups.get(key) ?? { uid: r.uid, players: [], before, after };
    group.players.push(r.playerName);
    groups.set(key, group);
  }
  const groupId = String(input.poll.groupId);
  const messageId = String(input.poll.messageId ?? input.pollId);
  const question = String(input.poll.question ?? '');
  for (const g of groups.values()) {
    await trySend({
      kind: 'pollVoteReplaced',
      groupId,
      recipients: { uids: [g.uid] },
      actor: input.actor,
      // The poll's message, so deleting it takes these items too (CHAT-8).
      target: { type: 'message', id: messageId },
      route: `/g/${groupId}/chat/m/${messageId}`,
      params: { question, players: joinNames(g.players), answer: g.after },
      body: voteReplacedBody(input.actor.name, question, g.players, g.before, g.after),
      dedupeKey: randomUUID(),
    });
  }
}

/**
 * A player taken off the roster stops voting (#96): their votes on polls
 * still open go, and those polls are counted again. Closed polls keep
 * theirs, as their result.
 */
export async function removePlayerPollVotes(playerId: string): Promise<void> {
  const votes = await db().collection(Collections.pollPlayerVotes).where('playerId', '==', playerId).limit(500).get();
  const recount = new Set<string>();
  for (const vote of votes.docs) {
    const pollId = String(vote.get('pollId'));
    const poll = await db().collection(Collections.polls).doc(pollId).get();
    if (poll.exists && !pollIsOpen(poll.data()!)) continue;
    await vote.ref.delete();
    recount.add(pollId);
  }
  for (const pollId of recount) await recountPoll(pollId);
}
