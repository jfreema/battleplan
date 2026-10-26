// What createGroup and adminUpdateGroup take as a team color (TEAM-5): iOS
// 1.0 still offers the retired colors, which are stored as their current
// ones.
import { describe, expect, it } from 'vitest';
import { RETIRED_TEAM_COLORS, TEAM_COLORS } from '../../src/shared/constants.js';
import { teamColor } from '../../src/shared/team_color.js';
import { UpdateGroupInput } from '../../src/admin/inputs.js';

describe('teamColor', () => {
  it('keeps every palette color', () => {
    for (const c of TEAM_COLORS) expect(teamColor.parse(c)).toBe(c);
  });

  it('stores a retired color as the one it shows as now', () => {
    expect(teamColor.parse('#1D4ED8')).toBe('#2F5BEA');
    expect(teamColor.parse('#9333EA')).toBe('#7C3AED');
    for (const [old, now] of Object.entries(RETIRED_TEAM_COLORS)) expect(teamColor.parse(old)).toBe(now);
  });

  it('refuses anything else', () => {
    for (const c of ['#123456', '#2f5bea', 'blue', '']) expect(teamColor.safeParse(c).success).toBe(false);
  });

  it("maps a retired team or bubble color in the admin's team edit", () => {
    const parsed = UpdateGroupInput.parse({ groupId: 'g1', color: '#9333EA', chatTheme: { bubbleColor: '#1D4ED8' } });
    expect(parsed.color).toBe('#7C3AED');
    expect(parsed.chatTheme?.bubbleColor).toBe('#2F5BEA');
    expect(UpdateGroupInput.parse({ groupId: 'g1', chatTheme: { bubbleColor: '#FF7AC8' } }).chatTheme?.bubbleColor).toBe('#FF7AC8');
  });
});
