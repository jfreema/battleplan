import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { appCheckEnforced } from '../../src/shared/callable.js';

// App Check on every callable from one switch (ARCH §6.9, docs/DEVELOPMENT.md).

// Records the options each callable is declared with instead of building it.
vi.mock('firebase-functions/v2/https', async (original) => ({
  ...(await original<typeof import('firebase-functions/v2/https')>()),
  onCall: (opts: object, handler: unknown) => ({ declaredWith: opts, handler }),
}));

type Declared = { declaredWith: { enforceAppCheck?: boolean; secrets?: unknown[] } };

/** Every exported callable, by name, with the options it was declared with. */
async function callables(): Promise<Map<string, Declared>> {
  // The Storage trigger needs a bucket name to be declared at all.
  process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: 'demo-battleplan', storageBucket: 'demo-battleplan.appspot.com' });
  const index: Record<string, unknown> = await import('../../src/index.js');
  const found = new Map<string, Declared>();
  for (const [name, value] of Object.entries(index)) {
    if (value && typeof value === 'object' && 'declaredWith' in value) found.set(name, value as Declared);
  }
  return found;
}

function sourceFiles(dir: string): string[] {
  return readdirSync(dir).flatMap((entry) => {
    const path = join(dir, entry);
    return statSync(path).isDirectory() ? sourceFiles(path) : path.endsWith('.ts') ? [path] : [];
  });
}

describe('appCheckEnforced', () => {
  it('defaults to monitor mode', () => {
    expect(appCheckEnforced({})).toBe(false);
  });

  it('takes ENFORCE_APP_CHECK for one project', () => {
    expect(appCheckEnforced({ ENFORCE_APP_CHECK: 'true' })).toBe(true);
    expect(appCheckEnforced({ ENFORCE_APP_CHECK: ' TRUE ' })).toBe(true);
    expect(appCheckEnforced({ ENFORCE_APP_CHECK: 'false' })).toBe(false);
  });

  it('ignores anything else', () => {
    expect(appCheckEnforced({ ENFORCE_APP_CHECK: 'yes' })).toBe(false);
    expect(appCheckEnforced({ ENFORCE_APP_CHECK: '' })).toBe(false);
  });
});

describe('callables', () => {
  const firebaseConfig = process.env.FIREBASE_CONFIG;
  afterEach(() => {
    delete process.env.ENFORCE_APP_CHECK;
    if (firebaseConfig === undefined) delete process.env.FIREBASE_CONFIG;
    else process.env.FIREBASE_CONFIG = firebaseConfig;
    vi.resetModules();
  });

  it('all import onCall from shared/callable', () => {
    const direct = sourceFiles('src').filter(
      (path) =>
        !path.endsWith(join('shared', 'callable.ts')) &&
        /import\s*\{[^}]*\bonCall\b[^}]*\}\s*from\s*'firebase-functions\/v2\/https'/.test(readFileSync(path, 'utf8')),
    );
    expect(direct).toEqual([]);
  });

  it('are in monitor mode by default, including the signed-out ones', async () => {
    const all = await callables();
    expect(all.size).toBeGreaterThan(50);
    for (const [name, callable] of all) expect(callable.declaredWith.enforceAppCheck, name).toBe(false);
    expect(all.has('getInvitePreview')).toBe(true);
    expect(all.has('logClientError')).toBe(true);
  });

  it('all enforce when the switch is on, keeping their own options', async () => {
    process.env.ENFORCE_APP_CHECK = 'true';
    const all = await callables();
    for (const [name, callable] of all) expect(callable.declaredWith.enforceAppCheck, name).toBe(true);
    expect(all.get('sendEmailInvites')?.declaredWith.secrets?.length).toBe(1);
  });
});
