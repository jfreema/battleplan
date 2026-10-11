import { describe, expect, it } from 'vitest';
import { compositeId, rsvpId } from '../../src/shared/ids.js';

describe('composite IDs', () => {
  it('joins with the shared separator', () => {
    expect(rsvpId('event1', 'player1')).toBe('event1_player1');
  });

  it('rejects parts that contain the separator', () => {
    expect(() => compositeId('a_b', 'c')).toThrow();
  });
});
