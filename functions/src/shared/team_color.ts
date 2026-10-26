// The team color a callable accepts (TEAM-1, TEAM-5): the palette, or a
// retired color, which is stored as the one it shows as now. iOS 1.0
// (build 277) still offers the retired Royal blue and Violet, so they must
// keep working there.
import { z } from 'zod';
import { RETIRED_TEAM_COLORS, TEAM_COLORS } from './constants.js';

const retired = Object.keys(RETIRED_TEAM_COLORS) as (keyof typeof RETIRED_TEAM_COLORS)[];

/** A team color in, its current palette color out. */
export const teamColor = z
  .enum([...TEAM_COLORS, ...retired])
  .transform((c): (typeof TEAM_COLORS)[number] => (c in RETIRED_TEAM_COLORS ? RETIRED_TEAM_COLORS[c as keyof typeof RETIRED_TEAM_COLORS] : (c as (typeof TEAM_COLORS)[number])));
