import { describe, expect, it } from 'vitest';
import { orphanMessageFiles } from '../../src/chat/service.js';

// Photos wait in the tray above the message box and upload before Send
// (CHAT-3, #26); dailyCleanup removes the ones no message shows.
describe('orphanMessageFiles (dailyCleanup)', () => {
  const now = Date.parse('2026-11-17T12:00:00Z');
  const cutoff = now - 86_400_000;
  const old = '2026-11-15T00:00:00Z';
  const recent = '2026-11-17T11:00:00Z';
  const f = (name: string, timeCreated: unknown = old) => ({ name: `groups/g1/messages/${name}`, timeCreated });

  it('removes day-old photos of a message never sent, or taken out before Send', () => {
    const shown = new Map([['m1', ['groups/g1/messages/m1/0.jpg', 'groups/g1/messages/m1/0_thumb.jpg']]]);
    const files = [f('m1/0.jpg'), f('m1/0_thumb.jpg'), f('m1/3.jpg'), f('tray/0.jpg'), f('tray2/1.jpg', recent)];
    expect(orphanMessageFiles('g1', files, shown, cutoff)).toEqual([
      'groups/g1/messages/m1/3.jpg',
      'groups/g1/messages/tray/0.jpg',
    ]);
  });

  it('leaves photos younger than a day, without a time, or outside the folder', () => {
    const files = [
      f('a/0.jpg', recent),
      f('b/0.jpg', null),
      f('c/0.jpg', 'not a date'),
      { name: 'groups/g2/messages/d/0.jpg', timeCreated: old },
      { name: 'groups/g1/documents/d/x.pdf', timeCreated: old },
    ];
    expect(orphanMessageFiles('g1', files, new Map(), cutoff)).toEqual([]);
  });
});
