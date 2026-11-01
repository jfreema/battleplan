// The per-instance cache for repeated reads (ARCH §10.2).
import { afterEach, describe, expect, it } from 'vitest';
import { setCacheTtlForTests, TtlCache } from '../../src/shared/ttl_cache.js';

describe('a minute-long cache of reads', () => {
  afterEach(() => setCacheTtlForTests(0));

  it('loads only what is missing or stale, and forgets on request', async () => {
    setCacheTtlForTests(60_000);
    const cache = new TtlCache<string>();
    const asked: string[][] = [];
    const load = async (keys: string[]) => {
      asked.push(keys);
      return new Map(keys.filter((k) => k !== 'gone').map((k) => [k, `v-${k}`]));
    };
    expect([...(await cache.getMany(['a', 'b', 'gone'], load, 0))]).toEqual([
      ['a', 'v-a'],
      ['b', 'v-b'],
    ]);
    await cache.getMany(['a', 'b', 'c'], load, 30_000);
    // a and b were fresh; what wasn't found is asked again.
    expect(asked).toEqual([['a', 'b', 'gone'], ['c']]);
    cache.forget('a');
    await cache.getMany(['a', 'b'], load, 30_000);
    expect(asked.at(-1)).toEqual(['a']);
    // A minute on, everything is read again.
    await cache.getMany(['b'], load, 60_001);
    expect(asked.at(-1)).toEqual(['b']);
  });

  it('keeps nothing when off, and empties when full', async () => {
    let loads = 0;
    const load = async (keys: string[]) => {
      loads++;
      return new Map(keys.map((k) => [k, k]));
    };
    const off = new TtlCache<string>();
    await off.getMany(['a'], load);
    await off.getMany(['a'], load);
    expect(loads).toBe(2);
    setCacheTtlForTests(60_000);
    const small = new TtlCache<string>(2);
    await small.getMany(['a', 'b'], load, 0);
    await small.getMany(['c'], load, 0);
    await small.getMany(['a'], load, 0);
    expect(loads).toBe(5);
  });
});
