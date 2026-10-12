// Poll tallies and notification wording (SPEC POLL-2, POLL-4, NOTIF-5).
import { describe, expect, it } from 'vitest';
import { lastMessagePreviewOf } from '../../src/chat/service.js';
import { pollClosedBody, pollCreatedBody, resultPhrase, tallyOf } from '../../src/polls/service.js';

const options = ['Saturday', 'Sunday', 'Either'].map((text, i) => ({ id: String(i), text }));

describe('tallyOf', () => {
  it('counts options and voters, skipping repeats and unknown choices', () => {
    expect(tallyOf(options, [{ optionIds: ['0', '0', '2'] }, { optionIds: ['9'] }, { optionIds: 'x' }, {}])).toEqual({
      voteCounts: { 0: 1, 1: 0, 2: 1 },
      voterCount: 1,
    });
  });
});

describe('resultPhrase', () => {
  it('names the leader, the tie, or no votes', () => {
    expect(resultPhrase(options, { 0: 5, 1: 2 })).toBe('Saturday (5 votes)');
    expect(resultPhrase(options, { 1: 1 })).toBe('Sunday (1 vote)');
    expect(resultPhrase(options, { 0: 2, 1: 2 })).toBe('Tie: Saturday and Sunday (2 votes each)');
    expect(resultPhrase(options, { 0: 1, 1: 1, 2: 1 })).toBe('Tie: Saturday, Sunday, and Either (1 vote each)');
    expect(resultPhrase(options, {})).toBe('No votes');
  });

  it('words the notifications', () => {
    expect(pollClosedBody(' Which day? ', options, { 2: 3 })).toBe('Poll closed: Which day? Either (3 votes)');
    expect(pollCreatedBody('Alex', 'Which day?')).toBe('Alex created a poll: Which day?');
    expect(pollCreatedBody(' ', 'Which day?')).toBe('Someone created a poll: Which day?');
  });

  it("previews a poll in the switcher by its question", () => {
    expect(lastMessagePreviewOf({ authorName: 'Alex', type: 'poll', text: 'Which day?' }).text).toBe('Poll: Which day?');
    expect(lastMessagePreviewOf({ authorName: 'Alex', type: 'poll', text: '' }).text).toBe('Poll');
  });
});
