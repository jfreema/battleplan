// Polls triggers (ARCH §6.4 trigger map).
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { recountPoll } from './service.js';

/** pollVotes written → the poll's voteCounts and voterCount (POLL-2). */
export const onPollVoteWritten = onDocumentWritten('pollVotes/{voteId}', async (event) => {
  const pollId = (event.data?.after.get('pollId') ?? event.data?.before.get('pollId')) as string | undefined;
  if (typeof pollId === 'string' && pollId) await recountPoll(pollId);
});
