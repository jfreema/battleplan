// The only code that builds Battleplan URLs on the server (ARCH §6.6).
import { projectId } from '../shared/project.js';

/** The web host links point at: our domain in prod, the dev Hosting domain otherwise. */
export function linkHost(): string {
  return projectId() === 'battleplan-prod' ? 'getbattleplan.app' : `${projectId()}.web.app`;
}

/** https://<host>/join/<CODE> (INV-2, INV-9). */
export function joinUrl(code: string): string {
  return `https://${linkHost()}/join/${code}`;
}

/** https://<host>/g/<groupId>/chat, for emails and notifications. */
export function teamUrl(groupId: string): string {
  return `https://${linkHost()}/g/${groupId}/chat`;
}

/** Where an emailed sign-in or setup link lands (ARCH §6.6). */
export function activateUrl(): string {
  return `https://${linkHost()}/activate`;
}
