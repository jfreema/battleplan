// The answer page an RSVP email links to (SPEC SCHED-14, ARCH §6.15): a
// small HTML page in the website's look, no framework and no script. Pure
// functions, so the wording can be tested without Firestore.
import { escapeHtml } from '../email/service.js';

export type AnswerStatus = 'going' | 'maybe' | 'not_going';

/** Who an answer is for, as an email or the page names them. */
export interface AnswerFor {
  /** The player's first name. */
  name: string;
  /** The person answering is this player. */
  self: boolean;
}

/** "Is Emma going?", or "Are you going?" for one's own player: each player is asked on their own (PLAYER-11). */
export function questionOf(person: AnswerFor): string {
  return person.self ? 'Are you going?' : `Is ${person.name} going?`;
}

/** "Emma is going.", "You aren't going.", "Emma might go." */
export function answeredLine(person: AnswerFor, status: AnswerStatus): string {
  const who = person.self ? 'You' : person.name;
  if (status === 'maybe') return `${who} might go.`;
  const verb = person.self ? 'are' : 'is';
  return status === 'going' ? `${who} ${verb} going.` : `${who} ${verb}n't going.`;
}

const LABELS: Record<AnswerStatus, string> = { going: 'Going', maybe: 'Maybe', not_going: 'Not going' };

const STYLE = `
:root{color-scheme:light dark;--brand:#2f5bea;--bg:#fff;--surface:#f4f6fb;--border:#d9deea;--text:#1a1c22;--muted:#4a5163}
@media (prefers-color-scheme:dark){:root{--brand:#5a7ff5;--bg:#121317;--surface:#1b1d22;--border:#2f323a;--text:#e6e8ef;--muted:#b0b6c4}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--text);font:17px/1.5 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
a{color:var(--brand)}
main{max-width:480px;margin:0 auto;padding:32px 20px 48px}
.team{color:var(--muted);font-size:15px;margin:0}
h1{font-size:26px;line-height:1.2;margin:4px 0 8px}
.when{margin:0 0 24px;color:var(--muted)}
fieldset{border:0;padding:0;margin:0 0 28px}
legend{font-weight:600;font-size:19px;margin-bottom:12px;padding:0}
.error{font-weight:600;margin:0 0 20px}
.choices{display:grid;gap:10px}
.choices input{position:absolute;opacity:0;width:1px;height:1px}
.choices label{display:block;padding:14px 18px;border:2px solid var(--border);border-radius:14px;font-weight:600;cursor:pointer}
.choices input:checked+label{border-color:var(--brand);background:var(--surface);color:var(--brand)}
.choices input:focus-visible+label{outline:3px solid var(--brand);outline-offset:2px}
label.note{display:block;font-weight:600;margin:16px 0 6px}
textarea{width:100%;min-height:72px;padding:10px 12px;border:2px solid var(--border);border-radius:12px;background:var(--bg);color:var(--text);font:inherit}
button{width:100%;margin-top:0;padding:14px;border:0;border-radius:999px;background:var(--brand);color:#fff;font:inherit;font-weight:700;cursor:pointer}
.done{font-size:22px;font-weight:700;margin:0 0 16px}
.links a{color:var(--brand);font-weight:600;margin-right:20px}
.small{color:var(--muted);font-size:14px;margin-top:28px}
`;

function page(title: string, body: string): string {
  return (
    '<!doctype html><html lang="en"><head><meta charset="utf-8">' +
    '<meta name="viewport" content="width=device-width,initial-scale=1">' +
    '<meta name="robots" content="noindex">' +
    `<title>${escapeHtml(title)} · Battleplan</title><style>${STYLE}</style></head>` +
    `<body><main>${body}</main></body></html>`
  );
}

/** The event at the top of every page. */
export interface EventLines {
  team: string;
  title: string;
  /** "Tue, Oct 21 at 6:00 PM · Riverside Park" */
  when: string;
}

function head(e: EventLines): string {
  return (
    `<p class="team">${escapeHtml(e.team)}</p>` +
    `<h1>${escapeHtml(e.title)}</h1>` +
    `<p class="when">${escapeHtml(e.when)}</p>`
  );
}

/**
 * One player on the answer page: who, their place in the link's list (which
 * names their fields), and the answer and note it shows.
 */
export interface AnswerRow {
  person: AnswerFor;
  index: number;
  picked: AnswerStatus | null;
  note: string;
}

/**
 * The form: each player on their own (PLAYER-11), named, with their own
 * answers (the one tapped in the email, or the one saved, picked) and note,
 * then Send. It posts back to the same address; opening it never answers.
 */
export function answerFormPage(input: {
  event: EventLines;
  rows: AnswerRow[];
  allowMaybe: boolean;
  answeringAs: string;
  eventUrl: string;
  /** Why Send saved nothing. */
  error?: string;
}): string {
  const statuses: AnswerStatus[] = input.allowMaybe ? ['going', 'maybe', 'not_going'] : ['going', 'not_going'];
  const one = input.rows.length === 1;
  const noteLabel = (p: AnswerFor) => (one ? 'Note (optional)' : p.self ? 'Your note (optional)' : `Note for ${p.name} (optional)`);
  const rows = input.rows
    .map((row) => {
      const choices = statuses
        .map(
          (s) =>
            `<input type="radio" id="s${row.index}-${s}" name="status-${row.index}" value="${s}"` +
            `${one ? ' required' : ''}${s === row.picked ? ' checked' : ''}>` +
            `<label for="s${row.index}-${s}">${LABELS[s]}</label>`,
        )
        .join('');
      return (
        `<fieldset><legend>${escapeHtml(questionOf(row.person))}</legend><div class="choices">${choices}</div>` +
        `<label class="note" for="note-${row.index}">${escapeHtml(noteLabel(row.person))}</label>` +
        `<textarea id="note-${row.index}" name="note-${row.index}" maxlength="200" placeholder="Leaving at halftime">` +
        `${escapeHtml(row.note)}</textarea></fieldset>`
      );
    })
    .join('');
  return page(
    input.event.title,
    head(input.event) +
      (input.error ? `<p class="error" role="alert">${escapeHtml(input.error)}</p>` : '') +
      `<form method="post">${rows}<button type="submit">Send</button></form>` +
      `<p class="small">Answering as ${escapeHtml(input.answeringAs)}. ` +
      `<a href="${escapeHtml(input.eventUrl)}">Open in Battleplan</a></p>`,
  );
}

/** After Send: what was saved for each player answered, and the way to change it. */
export function answeredPage(input: {
  event: EventLines;
  answers: { person: AnswerFor; status: AnswerStatus }[];
  changeUrl: string;
  eventUrl: string;
}): string {
  const lines = input.answers.map((a) => answeredLine(a.person, a.status)).join(' ');
  return page(
    input.event.title,
    head(input.event) +
      `<p class="done">Thanks! ${escapeHtml(lines)}</p>` +
      '<p class="links">' +
      `<a href="${escapeHtml(input.changeUrl)}">Change answer</a>` +
      `<a href="${escapeHtml(input.eventUrl)}">Open in Battleplan</a></p>`,
  );
}

/** A link that can't take an answer, and why, with the way into the app. */
export function answerProblemPage(input: { heading: string; body: string; url: string; label: string }): string {
  return page(
    input.heading,
    `<h1>${escapeHtml(input.heading)}</h1>` +
      `<p>${escapeHtml(input.body)}</p>` +
      `<p class="links"><a href="${escapeHtml(input.url)}">${escapeHtml(input.label)}</a></p>`,
  );
}
