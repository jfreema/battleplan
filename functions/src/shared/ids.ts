import { ID_SEPARATOR } from './constants.js';

/** Composite document IDs (ARCH §6.2), built the same way as core/ids.dart. */
export function compositeId(a: string, b: string): string {
  if (a.includes(ID_SEPARATOR) || b.includes(ID_SEPARATOR)) {
    throw new Error(`IDs in a composite key must not contain "${ID_SEPARATOR}"`);
  }
  return `${a}${ID_SEPARATOR}${b}`;
}

export const groupMemberId = (groupId: string, uid: string) => compositeId(groupId, uid);
export const rsvpId = (eventId: string, participantId: string) => compositeId(eventId, participantId);
