// Where the App Review demo seed may write (SPEC §10: "An App Review demo
// account with a seeded team"). Only the dev project, and only with an
// explicit flag, or the local emulators under a demo- project ID. Never
// prod: App Review runs against a build pointed at dev until launch, and a
// prod demo account is made by hand then (docs/DEVELOPMENT.md).

/** The dev Firebase project (ARCH §5.7). */
export const DEV_PROJECT = 'battleplan-dev-ecce4';

/** The flag that says, yes, write the demo team to the dev project. */
export const CONFIRM_FLAG = '--write-to-dev';

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
  if (projectId !== DEV_PROJECT) {
    return { error: `Refusing to seed ${projectId}: the demo seed writes only to ${DEV_PROJECT} or the emulators.` };
  }
  if (!argv.includes(CONFIRM_FLAG)) {
    return { error: `Writing to ${DEV_PROJECT} needs ${CONFIRM_FLAG}.` };
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
