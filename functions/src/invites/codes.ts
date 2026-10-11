import { randomInt } from 'node:crypto';
import { INVITE_CODE_ALPHABET, Limits } from '../shared/constants.js';

/**
 * A new invite code: 8 characters from an alphabet without look-alikes
 * (no 0/O/1/I/L), about 40 bits (ARCH §6.6). Stored without the dash.
 */
export function newInviteCode(): string {
  let code = '';
  for (let i = 0; i < Limits.inviteCodeLength; i++) {
    code += INVITE_CODE_ALPHABET[randomInt(INVITE_CODE_ALPHABET.length)];
  }
  return code;
}

/** Normalizes typed or scanned input: uppercase, no dashes or spaces. */
export function normalizeCode(input: string): string {
  return input.toUpperCase().replace(/[^0-9A-Z]/g, '');
}

/** K7XPM2QR → K7XP-M2QR, for display. */
export function formatCode(code: string): string {
  return code.length === 8 ? `${code.slice(0, 4)}-${code.slice(4)}` : code;
}
