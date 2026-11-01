// Runs before every test file: the per-instance caches are off, so each
// call reads what the test just wrote.
import { setCacheTtlForTests } from '../src/shared/ttl_cache.js';

setCacheTtlForTests(0);
