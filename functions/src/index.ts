// Exports only, no logic (ARCH §6.4).
import { setGlobalOptions } from 'firebase-functions/v2';

setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

export { ensureUserProfile, recordSignInMethodChange, signOutEverywhere } from './accounts/handlers.js';
export { logClientError } from './ops/handlers.js';
