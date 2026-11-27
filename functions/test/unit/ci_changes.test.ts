// CI leaves the Functions job out of a push that can't affect it
// (tools/ci_changes.sh, ARCH §9). A rule there may leave the job off a path
// only if nothing the job runs reads the file, so this finds every file
// outside functions/ that the server's tests open by name, and checks that a
// change to it still runs the job. The app's side is
// test/tools/ci_changes_test.dart, which also tests the rules themselves.
import { execFileSync } from 'node:child_process';
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative, resolve, sep } from 'node:path';
import { describe, expect, it } from 'vitest';

/** What tools/ci_changes.sh says a push that changed `paths` needs. */
function needs(paths: string[]): Record<string, boolean> {
  const out = execFileSync('bash', ['../tools/ci_changes.sh', '--classify'], { input: paths.join('\n'), encoding: 'utf8' });
  return Object.fromEntries(out.trim().split('\n').map((line) => [line.split('=')[0], line.endsWith('=true')]));
}

function sourceFiles(dir: string): string[] {
  return readdirSync(dir).flatMap((entry) => {
    const path = join(dir, entry);
    return statSync(path).isDirectory() ? sourceFiles(path) : path.endsWith('.ts') ? [path] : [];
  });
}

describe('the paths CI runs the Functions job for', () => {
  it('include the server itself, its tests, the rules, and the demo seed', () => {
    for (const path of ['functions/src/chat/service.ts', 'functions/test/unit/polls.test.ts', 'firestore.rules', 'storage.rules', 'tools/seed/demo.ts']) {
      expect(needs([path]).functions, path).toBe(true);
    }
    // And not the app's own code, the website, or a workflow started by hand.
    expect(needs(['lib/main.dart', 'test/chat_test.dart', 'website/index.html', 'web/index.html', 'docs/SPEC.md', '.github/workflows/release.yml']).functions).toBe(false);
  });

  // The tests run from functions/, so a file outside it is named '../...'.
  // Every quoted '../' path that exists in the repo counts; an import of a
  // file beside the test isn't one, since from here it points nowhere. A path
  // put together at run time isn't found, so a test that reads a new place
  // still needs its rule checked by hand.
  it('include every file outside functions/ that these tests name', () => {
    const repo = resolve(process.cwd(), '..');
    const named = new Set<string>();
    for (const file of sourceFiles('test')) {
      for (const match of readFileSync(file, 'utf8').matchAll(/['"`](\.\.\/[\w.\-/ ]+)['"`]/g)) {
        const path = resolve(process.cwd(), match[1]);
        const inRepo = relative(repo, path).split(sep).join('/');
        if (inRepo.startsWith('..') || inRepo.startsWith('functions/') || !existsSync(path)) continue;
        // A folder is read through the files in it.
        named.add(statSync(path).isDirectory() ? `${inRepo}/a_file` : inRepo);
      }
    }
    // What the tests read today, so the search itself is known to work.
    expect([...named]).toEqual(expect.arrayContaining(['firestore.rules', 'storage.rules', 'shared/constants.json', 'web/firebase-messaging-sw.js']));
    for (const path of named) {
      expect(needs([path]).functions, path).toBe(true);
    }
  });
});
