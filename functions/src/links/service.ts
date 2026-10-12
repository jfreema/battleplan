// The only code that builds Battleplan URLs on the server (ARCH §6.6). The
// website is at the root of the domain and the web app under /app (D40):
// invite links stay short at /join/<CODE>, and everything that opens the app
// goes to /app/....
import { projectId } from '../shared/project.js';

/** Where the web app lives on the domain. */
export const APP_PREFIX = '/app';

/** The web host links point at: our domain in prod, the dev Hosting domain otherwise. */
export function linkHost(): string {
  return projectId() === 'battleplan-prod' ? 'getbattleplan.app' : `${projectId()}.web.app`;
}

/** https://<host>/app<route>, for an app route like `/g/abc/chat`. */
export function appUrl(route: string): string {
  const path = route.startsWith('/') ? route : `/${route}`;
  return `https://${linkHost()}${APP_PREFIX}${path}`;
}

/** https://<host>/join/<CODE> (INV-2, INV-9): short, for links and QR codes. */
export function joinUrl(code: string): string {
  return `https://${linkHost()}/join/${code}`;
}

/** https://<host>/app/g/<groupId>/chat, for emails and notifications. */
export function teamUrl(groupId: string): string {
  return appUrl(`/g/${groupId}/chat`);
}

/** Where an emailed sign-in or setup link lands (ARCH §6.6). */
export function activateUrl(): string {
  return appUrl('/activate');
}
