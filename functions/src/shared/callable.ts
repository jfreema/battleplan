import {
  onCall as firebaseOnCall,
  type CallableFunction,
  type CallableOptions,
  type CallableRequest,
  type CallableResponse,
} from 'firebase-functions/v2/https';

/**
 * THE App Check switch for every callable (ARCH §6.9, docs/DEVELOPMENT.md).
 * false is monitor mode: tokens are checked and logged, and requests without
 * one still run. Set true once the console shows nearly all traffic verified.
 */
const enforceAppCheckByDefault = false;

/**
 * Whether callables refuse requests without a valid App Check token.
 * `ENFORCE_APP_CHECK=true|false` (e.g. in a local `functions/.env.<project>`)
 * overrides the default for one project.
 */
export function appCheckEnforced(env: NodeJS.ProcessEnv = process.env): boolean {
  const value = env.ENFORCE_APP_CHECK?.trim().toLowerCase();
  if (value === 'true') return true;
  if (value === 'false') return false;
  return enforceAppCheckByDefault;
}

/** A callable's options with App Check from the one switch above. */
export function callableOptions<T>(opts: CallableOptions<T> = {}): CallableOptions<T> {
  return { ...opts, enforceAppCheck: appCheckEnforced() };
}

/**
 * `onCall` with App Check applied. Every handler imports this one, never
 * firebase-functions' (test/unit/app_check.test.ts checks). App Check is
 * separate from sign-in: `getInvitePreview` and `logClientError` still work
 * signed out, as long as the app sends a token once enforced.
 */
/* eslint-disable @typescript-eslint/no-explicit-any -- the same defaults as firebase-functions */
export function onCall<T = any, Return = any | Promise<any>, Stream = unknown>(
  opts: CallableOptions<T>,
  handler: (request: CallableRequest<T>, response?: CallableResponse<Stream>) => Return,
): CallableFunction<T, Return extends Promise<unknown> ? Return : Promise<Return>, Stream>;
export function onCall<T = any, Return = any | Promise<any>, Stream = unknown>(
  handler: (request: CallableRequest<T>, response?: CallableResponse<Stream>) => Return,
): CallableFunction<T, Return extends Promise<unknown> ? Return : Promise<Return>, Stream>;
export function onCall(
  optsOrHandler: CallableOptions<any> | ((request: CallableRequest<any>, response?: CallableResponse<any>) => any),
  handler?: (request: CallableRequest<any>, response?: CallableResponse<any>) => any,
) {
  /* eslint-enable @typescript-eslint/no-explicit-any */
  return typeof optsOrHandler === 'function'
    ? firebaseOnCall(callableOptions(), optsOrHandler)
    : firebaseOnCall(callableOptions(optsOrHandler), handler!);
}
