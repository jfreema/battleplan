import { describe, expect, it } from 'vitest';
import { joinNames, parsePastedRoster, playerLabel } from '../../src/players/roster.js';

describe('parsePastedRoster (PLAYER-1)', () => {
  it('merges lines for the same player into one with several guardians', () => {
    const { players, problems } = parsePastedRoster(
      'Emma Rodriguez, Maria Rodriguez, maria@example.com\n' +
        'emma rodriguez, Luis Rodriguez, luis@example.com\n' +
        '\n' +
        'Arjun Shah, Priya Shah, priya@example.com\n' +
        'Noah Bennett\n',
    );
    expect(problems).toEqual([]);
    expect(players.map((p) => p.name)).toEqual(['Emma Rodriguez', 'Arjun Shah', 'Noah Bennett']);
    expect(players[0].guardians.map((g) => g.email)).toEqual(['maria@example.com', 'luis@example.com']);
    expect(players[2].guardians).toEqual([]);
  });

  it('reports bad emails and a fifth guardian', () => {
    const lines = ['Kid, A, a@x.com', 'Kid, B, b@x.com', 'Kid, C, c@x.com', 'Kid, D, d@x.com', 'Kid, E, e@x.com', 'Other, F, not-an-email'];
    const { players, problems } = parsePastedRoster(lines.join('\n'));
    expect(players[0].guardians).toHaveLength(4);
    expect(problems).toEqual(['Kid, E, e@x.com', 'Other, F, not-an-email']);
  });

  it('labels players by first name and number', () => {
    expect(playerLabel('Emma Rodriguez', '7')).toBe('Emma #7');
    expect(playerLabel('Noah Bennett', null)).toBe('Noah');
  });
});

describe('joinNames (NOTIF-5)', () => {
  it('lists players the way a sentence would', () => {
    expect(joinNames([])).toBe('');
    expect(joinNames(['Emma'])).toBe('Emma');
    expect(joinNames(['Emma', 'Liam'])).toBe('Emma and Liam');
    expect(joinNames(['Emma', 'Liam', 'Ava'])).toBe('Emma, Liam, and Ava');
  });
});
