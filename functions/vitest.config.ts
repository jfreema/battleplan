import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Rules tests share one emulator database, so run files one at a time.
    fileParallelism: false,
    testTimeout: 15000,
  },
});
