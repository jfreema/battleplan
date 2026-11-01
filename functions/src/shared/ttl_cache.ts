// A short-lived, in-memory cache for one function instance (ARCH §10.2):
// reads that many calls repeat within a minute, such as a busy chat's
// push recipients' profiles and devices. Each instance has its own, so a
// change shows within [ttlMs] everywhere; nothing that guards access may
// come from here.

/** How long entries last; the tests set 0, so every read is fresh. */
let ttlMs = 60_000;

/** For tests: 0 turns caching off. */
export function setCacheTtlForTests(ms: number): void {
  ttlMs = ms;
}

/** Values by key, each kept [ttlMs] from when it was read. */
export class TtlCache<V> {
  private readonly entries = new Map<string, { at: number; value: V }>();

  constructor(private readonly maxEntries = 5000) {}

  /**
   * The values for [keys]: the fresh ones from the cache, the rest from
   * [load] (in one call, for the keys it's given), kept for next time.
   */
  async getMany(keys: string[], load: (missing: string[]) => Promise<Map<string, V>>, now = Date.now()): Promise<Map<string, V>> {
    const out = new Map<string, V>();
    const missing: string[] = [];
    for (const key of keys) {
      const hit = this.entries.get(key);
      if (hit && now - hit.at < ttlMs) out.set(key, hit.value);
      else missing.push(key);
    }
    if (!missing.length) return out;
    const loaded = await load(missing);
    if (this.entries.size + missing.length > this.maxEntries) this.entries.clear();
    for (const key of missing) {
      const value = loaded.get(key);
      if (value === undefined) continue;
      out.set(key, value);
      if (ttlMs > 0) this.entries.set(key, { at: now, value });
    }
    return out;
  }

  /** Drops [key], so the next read loads it. */
  forget(key: string): void {
    this.entries.delete(key);
  }
}
