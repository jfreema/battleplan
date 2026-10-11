// Exports only, no logic (ARCH §6.4).
import { setGlobalOptions } from 'firebase-functions/v2';

setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

export {
  deleteAccount,
  ensureUserProfile,
  recordSignInMethodChange,
  signOutEverywhere,
} from './accounts/handlers.js';
export { onUserUpdated } from './accounts/triggers.js';
export {
  addMemberByEmail,
  archiveGroup,
  createGroup,
  deleteGroup,
  leaveGroup,
  removeMember,
  resendSetupEmail,
  transferOwnership,
  updateGroupMember,
} from './teams/handlers.js';
export {
  getInvitePreview,
  getTeamInvite,
  listEmailInvites,
  redeemInvite,
  resendEmailInvite,
  resetGroupInvite,
  revokeInvite,
  sendEmailInvites,
} from './invites/handlers.js';
export { logClientError } from './ops/handlers.js';
export { addPlayers, removePlayer } from './players/handlers.js';
