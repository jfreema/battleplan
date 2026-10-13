import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Rules tests share one emulator database, so run files one at a time.
    fileParallelism: false,
    testTimeout: 15000,
    // The first emulator call in a file can be slow, more so with coverage.
    hookTimeout: 30000,
    // `npm run emulators:coverage` (CI): unit, rules, and emulator tests
    // together must cover at least 80% of the server's domain and data code
    // (SPEC §8.1 Maintainability). The function wiring in index.ts,
    // handlers, triggers, and scheduled jobs is thin and left out; the
    // services, inputs, and shared helpers it calls are counted.
    coverage: {
      provider: 'v8',
      include: ['src/**/*.ts'],
      exclude: ['src/index.ts', 'src/**/handlers.ts', 'src/**/triggers.ts', 'src/ops/jobs.ts'],
      reporter: ['text-summary', 'lcov'],
      reportsDirectory: 'coverage',
      thresholds: { lines: 80 },
    },
  },
});
