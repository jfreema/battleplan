// Shared plays (SPEC BOARD-6, ARCH §6.14): what the public copy keeps, and
// the link's preview. Pure functions, no emulator.
import { describe, expect, it } from 'vitest';
import { playDescription, playPreviewPage, playTitle } from '../../src/plays/page.js';
import { imageOf, isShareId, newShareId, publicElement, publicPlay, publicSteps } from '../../src/plays/service.js';

describe('the public copy', () => {
  it("keeps the drawing, but no roster player's name or ID", () => {
    expect(publicElement({ k: 'm', id: 'a', x: 0.5, y: 0.25, s: 'team', l: 'Emma R.', p: 'emma' })).toEqual({
      k: 'm',
      id: 'a',
      x: 0.5,
      y: 0.25,
      s: 'team',
    });
    expect(publicElement({ k: 'm', id: 'b', x: 0.1, y: 0.2, s: 'opponent', l: 'SS' })).toEqual({
      k: 'm',
      id: 'b',
      x: 0.1,
      y: 0.2,
      s: 'opponent',
      l: 'SS',
    });
    expect(publicElement({ k: 'a', id: 'c', t: 'pass', pts: [0, 0, 1, 1], extra: 'x' })).toEqual({
      k: 'a',
      id: 'c',
      t: 'pass',
      pts: [0, 0, 1, 1],
    });
    expect(publicElement({ k: 'l', id: 'd', pts: [0.1, 0.2, 0.3, 0.4] })).toEqual({ k: 'l', id: 'd', pts: [0.1, 0.2, 0.3, 0.4] });
    expect(publicElement({ k: 'n', id: 'e', x: 0.3, y: 0.3, text: 'Go' })).toEqual({ k: 'n', id: 'e', x: 0.3, y: 0.3, text: 'Go' });
    expect(publicElement({ k: 'zone' })).toBeNull();
    expect(publicElement('m')).toBeNull();
  });

  it('keeps no more steps or elements than a play may have', () => {
    const steps = Array.from({ length: 12 }, () => ({
      elements: Array.from({ length: 160 }, (_, i) => ({ k: 'l', id: `l${i}`, pts: [0, 0, 1, 1] })),
    }));
    const kept = publicSteps(steps);
    expect(kept).toHaveLength(10);
    expect(kept[0]?.elements).toHaveLength(150);
    expect(publicSteps('nope')).toEqual([]);
    expect(publicSteps([null, { elements: 'x' }])).toEqual([{ elements: [] }, { elements: [] }]);
  });

  it('is the drawing, its name, and its note: no team, no author, no dates', () => {
    const copy = publicPlay({
      groupId: 'thunder',
      createdBy: 'coach',
      board: 'soccer',
      variant: 'half',
      title: 'Corner',
      note: 'Near post',
      steps: [{ elements: [] }],
      shareId: 'abc',
    });
    expect(copy).toEqual({ board: 'soccer', variant: 'half', title: 'Corner', note: 'Near post', steps: [{ elements: [] }] });
  });

  it("takes a PNG within the limit as the link's picture", () => {
    const png = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(16)]);
    expect(imageOf(png.toString('base64'))).toEqual(png);
    expect(imageOf(null)).toBeNull();
    expect(() => imageOf(Buffer.from('GIF89a and more').toString('base64'))).toThrow('bad-image');
    expect(() => imageOf(Buffer.concat([png, Buffer.alloc(1_000_000)]).toString('base64'))).toThrow('bad-image');
  });

  it('IDs are 12 URL-safe characters', () => {
    for (let i = 0; i < 100; i++) expect(isShareId(newShareId())).toBe(true);
    expect(isShareId('../plays/p1x')).toBe(false);
    expect(isShareId('short')).toBe(false);
  });
});

describe("the link's preview", () => {
  const card = { title: 'Box out', note: '', board: 'basketball', steps: 3, hasImage: true };
  const urls = {
    playUrl: 'https://getbattleplan.app/p/Ab3_x-9Kq2Zw',
    appPlayUrl: 'https://getbattleplan.app/app/p/Ab3_x-9Kq2Zw',
    imageUrl: 'https://getbattleplan.app/p/Ab3_x-9Kq2Zw/image.png',
    siteImage: 'https://getbattleplan.app/images/og.png',
  };

  it('names the play and says what it is', () => {
    expect(playTitle(card)).toBe('Box out · a play on Battleplan');
    expect(playTitle(null)).toBe('A play on Battleplan');
    expect(playDescription(card)).toBe('3 steps on a basketball court. Open it to watch it play out.');
    expect(playDescription({ ...card, steps: 1, board: 'mystery' })).toBe('Drawn on a whiteboard. Open it to see the play.');
    expect(playDescription({ ...card, note: ' Hit first,\n then go get it. ' })).toBe('Hit first, then go get it.');
    expect(playDescription({ ...card, note: 'x'.repeat(300) })).toHaveLength(200);
  });

  it("shows the play's picture, or the site's card without one", () => {
    const page = playPreviewPage(card, urls);
    expect(page).toContain('<meta property="og:image" content="https://getbattleplan.app/p/Ab3_x-9Kq2Zw/image.png">');
    expect(page).toContain('<a href="https://getbattleplan.app/app/p/Ab3_x-9Kq2Zw">Open the play</a>');
    expect(page).toContain('noindex');
    const plain = playPreviewPage({ ...card, hasImage: false }, urls);
    expect(plain).toContain('content="https://getbattleplan.app/images/og.png"');
    expect(playPreviewPage(null, urls)).toContain('<title>A play on Battleplan</title>');
  });

  it("escapes the coach's words", () => {
    const page = playPreviewPage({ ...card, title: '<script>"x"</script>' }, urls);
    expect(page).not.toContain('<script>');
    expect(page).toContain('&lt;script&gt;');
  });
});
