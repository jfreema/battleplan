// Where the App Review demo seed may write (SPEC §10: "An App Review demo
// account with a seeded team"). The dev or prod project, each only with its
// own explicit flag, or the local emulators under a demo- project ID. App
// Review uses prod, since Release iOS builds point there; the seed writes
// only the demo account and its "demo-" documents (D54).

/** The dev Firebase project (ARCH §5.7). */
export const DEV_PROJECT = 'battleplan-dev-ecce4';

/** The flag that says, yes, write the demo team to the dev project. */
export const CONFIRM_FLAG = '--write-to-dev';

/** The prod Firebase project, where App Review signs in. */
export const PROD_PROJECT = 'battleplan-prod';

/** The flag that says, yes, write the demo team to prod. */
export const PROD_CONFIRM_FLAG = '--write-to-prod';

/** The demo account's email unless DEMO_EMAIL says otherwise. */
export const DEFAULT_DEMO_EMAIL = 'appreview@getbattleplan.app';

/** App Review types this password; long enough that it isn't guessed. */
export const MIN_PASSWORD_LENGTH = 12;

export interface DemoTarget {
  projectId: string;
  emulators: boolean;
  email: string;
  password: string;
}

/** Reads the target from the command line and environment, or says why not. */
export function demoTarget(
  argv: readonly string[],
  env: Readonly<Record<string, string | undefined>>,
): DemoTarget | { error: string } {
  const at = argv.indexOf('--project');
  const projectId = at >= 0 ? argv[at + 1] : undefined;
  if (!projectId || projectId.startsWith('--')) {
    return { error: `Usage: demo --project ${DEV_PROJECT} ${CONFIRM_FLAG} (or --project demo-battleplan with the emulators)` };
  }
  const emulatorHosts = Boolean(env.FIRESTORE_EMULATOR_HOST || env.FIREBASE_AUTH_EMULATOR_HOST);
  const email = (env.DEMO_EMAIL ?? DEFAULT_DEMO_EMAIL).trim().toLowerCase();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return { error: `Not an email: ${email}` };

  if (projectId.startsWith('demo-')) {
    if (!env.FIRESTORE_EMULATOR_HOST || !env.FIREBASE_AUTH_EMULATOR_HOST) {
      return { error: 'A demo- project ID only works with the emulators: set FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST.' };
    }
    return { projectId, emulators: true, email, password: env.DEMO_PASSWORD || 'password' };
  }
  const flag = projectId === DEV_PROJECT ? CONFIRM_FLAG : projectId === PROD_PROJECT ? PROD_CONFIRM_FLAG : null;
  if (!flag) {
    return { error: `Refusing to seed ${projectId}: the demo seed writes only to ${DEV_PROJECT}, ${PROD_PROJECT}, or the emulators.` };
  }
  if (!argv.includes(flag)) {
    return { error: `Writing to ${projectId} needs ${flag}.` };
  }
  if (emulatorHosts) {
    return { error: 'The emulator hosts are set; unset them to write to the dev project.' };
  }
  const password = env.DEMO_PASSWORD ?? '';
  if (password.length < MIN_PASSWORD_LENGTH) {
    return { error: `Set DEMO_PASSWORD to at least ${MIN_PASSWORD_LENGTH} characters (it goes in the App Review notes, not the repo).` };
  }
  return { projectId, emulators: false, email, password };
}
