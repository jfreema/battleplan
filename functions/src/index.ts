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
  adminArchiveGroup,
  adminCreateUser,
  adminDashboard,
  adminDeleteGroup,
  adminDeleteUser,
  adminGetTeam,
  adminGetUser,
  adminListReports,
  adminListTeams,
  adminListUsers,
  adminOpenGroup,
  adminResolveReport,
  adminRevokeSessions,
  adminSendPasswordReset,
  adminSetGroupSuspended,
  adminSetSuperAdmin,
  adminSetUserDisabled,
  adminUpdateConfig,
  adminUpdateGroup,
  adminUpdatePlayer,
  adminUpdateUser,
} from './admin/handlers.js';
export {
  addMemberByEmail,
  adminSetGroupQuota,
  archiveGroup,
  createGroup,
  deleteGroup,
  deleteTeamMedia,
  leaveGroup,
  listTeamMedia,
  removeMember,
  resendSetupEmail,
  transferOwnership,
  updateGroupMember,
} from './teams/handlers.js';
export { dailyCleanup, onGroupFileAdded, onGroupFileRemoved } from './teams/triggers.js';
export { deleteMessage } from './chat/handlers.js';
export { onDocumentCreated, onDocumentDeleted } from './documents/triggers.js';
export { reportContent, resolveReport } from './safety/handlers.js';
export { onMessageCreated, onMessageUpdated } from './chat/triggers.js';
export {
  getInvitePreview,
  getTeamInvite,
  listEmailInvites,
  redeemInvite,
  resendEmailInvite,
  resetGroupInvite,
  revokeGroupInvite,
  revokeInvite,
  sendEmailInvites,
  updateGroupInvite,
} from './invites/handlers.js';
export { logClientError } from './ops/handlers.js';
export { tick } from './ops/jobs.js';
export { closePoll } from './polls/handlers.js';
export { onPollVoteWritten } from './polls/triggers.js';
export { saveEventSeries } from './schedule/handlers.js';
export { onEventWritten, onRsvpWritten } from './schedule/triggers.js';
export {
  addMyPlayer,
  addPlayers,
  inviteGuardian,
  removeGuardian,
  removePlayer,
  requestGuardianLink,
  resolveGuardianLink,
} from './players/handlers.js';
