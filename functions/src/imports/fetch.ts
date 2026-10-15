// Fetching a calendar link for an import (ARCH §6.13: remote retrieval
// checks hosts and redirects). A link is something a team admin pasted, so
// it may point anywhere: only https (or webcal, which is https) on the
// standard port, and never an address inside a private network, Google's
// metadata server included. Each redirect is checked the same way, and the
// address is checked as the connection is made, so a name can't resolve to
// one address for the check and another for the request.
import dns from 'node:dns';
import https from 'node:https';
import net from 'node:net';
import { HttpsError } from 'firebase-functions/v2/https';

/** Why a link was refused or failed; the app words each one. */
export type CalendarLinkError = 'bad-link' | 'calendar-unreachable' | 'not-a-calendar' | 'calendar-too-large';

function fail(code: CalendarLinkError): never {
  throw new HttpsError(code === 'bad-link' ? 'invalid-argument' : 'failed-precondition', code);
}

/** The https URL a pasted link stands for, or a `bad-link` refusal. */
export function calendarUrl(raw: string, base?: URL): URL {
  let url: URL;
  try {
    url = new URL(raw.trim().replace(/^webcals?:\/\//i, 'https://'), base);
  } catch {
    fail('bad-link');
  }
  if (url.protocol !== 'https:' || url.username || url.password) fail('bad-link');
  if (url.port && url.port !== '443') fail('bad-link');
  // A literal address skips the name lookup below, so check it here.
  const host = url.hostname.replace(/^\[|\]$/g, '');
  if (net.isIP(host) && !isPublicAddress(host)) fail('bad-link');
  return url;
}

/**
 * Whether [ip] is on the public internet: not loopback, private, link-local
 * (169.254.169.254 is the metadata server), shared, multicast, or reserved,
 * in IPv4 or IPv6 (IPv4-mapped addresses included).
 */
export function isPublicAddress(ip: string): boolean {
  const mapped = /^::ffff:(\d+\.\d+\.\d+\.\d+)$/i.exec(ip);
  if (mapped) return isPublicAddress(mapped[1]);
  if (net.isIPv4(ip)) {
    const [a, b] = ip.split('.').map(Number);
    return !(
      a === 0 ||
      a === 10 ||
      a === 127 ||
      (a === 100 && b >= 64 && b <= 127) ||
      (a === 169 && b === 254) ||
      (a === 172 && b >= 16 && b <= 31) ||
      (a === 192 && b === 168) ||
      (a === 192 && b === 0) ||
      (a === 198 && (b === 18 || b === 19)) ||
      a >= 224
    );
  }
  if (net.isIPv6(ip)) {
    const v = ip.toLowerCase();
    return !(
      v === '::' ||
      v === '::1' ||
      v.startsWith('fc') ||
      v.startsWith('fd') ||
      /^fe[89ab]/.test(v) ||
      v.startsWith('ff') ||
      v.startsWith('64:ff9b:') ||
      v.startsWith('2001:db8')
    );
  }
  return false;
}

/** dns.lookup, refusing any answer that isn't a public address. */
const publicLookup: net.LookupFunction = (hostname, options, callback) => {
  dns.lookup(hostname, options, (err, address, family) => {
    if (err) return callback(err, address, family);
    const answers = Array.isArray(address) ? address : [{ address, family }];
    if (answers.some((a) => !isPublicAddress(a.address))) {
      return callback(Object.assign(new Error('blocked-address'), { code: 'EBLOCKED' }), address, family);
    }
    callback(null, address, family);
  });
};

export interface FetchLimits {
  maxBytes: number;
  timeoutMs: number;
  maxRedirects: number;
}

const DEFAULT_LIMITS: FetchLimits = { maxBytes: 2_000_000, timeoutMs: 10_000, maxRedirects: 3 };

/** One GET: the body, or where it redirects to. */
function get(url: URL, limits: FetchLimits): Promise<{ status: number; location?: string; body?: string }> {
  return new Promise((resolve, reject) => {
    const req = https.get(
      url,
      {
        lookup: publicLookup,
        timeout: limits.timeoutMs,
        headers: { Accept: 'text/calendar, */*', 'User-Agent': 'Battleplan calendar import (+https://getbattleplan.app)' },
      },
      (res) => {
        const status = res.statusCode ?? 0;
        if (status >= 300 && status < 400 && res.headers.location) {
          res.resume();
          resolve({ status, location: res.headers.location });
          return;
        }
        if (status !== 200) {
          res.resume();
          resolve({ status });
          return;
        }
        const chunks: Buffer[] = [];
        let size = 0;
        res.on('data', (c: Buffer) => {
          size += c.length;
          if (size > limits.maxBytes) {
            req.destroy();
            reject(new HttpsError('failed-precondition', 'calendar-too-large'));
            return;
          }
          chunks.push(c);
        });
        res.on('end', () => resolve({ status, body: Buffer.concat(chunks).toString('utf8') }));
        res.on('error', reject);
      },
    );
    req.on('timeout', () => req.destroy(new Error('timeout')));
    req.on('error', reject);
  });
}

/**
 * The calendar at [raw], following up to three redirects, each checked like
 * the link itself. Refuses links that aren't https on a public address, and
 * answers that aren't iCalendar or are over 2 MB.
 */
export async function fetchCalendar(raw: string, limits: FetchLimits = DEFAULT_LIMITS): Promise<string> {
  let url = calendarUrl(raw);
  for (let hop = 0; hop <= limits.maxRedirects; hop++) {
    let res: Awaited<ReturnType<typeof get>>;
    try {
      res = await get(url, limits);
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      if ((e as { code?: string }).code === 'EBLOCKED') fail('bad-link');
      fail('calendar-unreachable');
    }
    if (res.location) {
      url = calendarUrl(res.location, url);
      continue;
    }
    if (res.status !== 200 || res.body === undefined) fail('calendar-unreachable');
    if (!/BEGIN:VCALENDAR/i.test(res.body)) fail('not-a-calendar');
    return res.body;
  }
  fail('calendar-unreachable');
}
