// Answering from an email (SPEC SCHED-14): the wording for a player or
// yourself, each asked on their own (PLAYER-11); the RSVP email with a link
// per answer for each player; the answer page's form; and the link helpers.
import { describe, expect, it } from 'vitest';
import { answeredLine, answeredPage, answerFormPage, answerProblemPage, questionOf } from '../../src/answers/page.js';
import { answerLinkId, answerToken, newAnswerToken, planRsvpEmails } from '../../src/answers/service.js';
import { rsvpReminderEmail } from '../../src/email/templates.js';

const emma = { name: 'Emma', self: false };
const liam = { name: 'Liam', self: false };
const me = { name: 'Sam', self: true };

describe('the wording', () => {
  it('asks about one player at a time, or you', () => {
    expect(questionOf(emma)).toBe('Is Emma going?');
    expect(questionOf(me)).toBe('Are you going?');
  });

  it('says what was saved', () => {
    expect(answeredLine(emma, 'going')).toBe('Emma is going.');
    expect(answeredLine(liam, 'not_going')).toBe("Liam isn't going.");
    expect(answeredLine(emma, 'maybe')).toBe('Emma might go.');
    expect(answeredLine(me, 'going')).toBe('You are going.');
    expect(answeredLine(me, 'not_going')).toBe("You aren't going.");
    expect(answeredLine(me, 'maybe')).toBe('You might go.');
  });
});

describe('the RSVP email', () => {
  const email = rsvpReminderEmail({
    to: 'maria@example.com',
    team: 'Thunder',
    title: 'vs. Eagles',
    when: 'Sat, Oct 24 at 10:00 AM',
    place: 'Field <3>',
    asks: [
      {
        question: 'Is Emma going?',
        going: 'https://getbattleplan.app/a/t?s=going',
        maybe: 'https://getbattleplan.app/a/t?s=maybe',
        notGoing: 'https://getbattleplan.app/a/t?s=not_going',
      },
    ],
    sentBy: 'Andy Bernard',
    eventUrl: 'https://getbattleplan.app/app/g/thunder/schedule/e/game',
  });

  it('names the team, the event, and the question, with a link for each answer', () => {
    expect(email.subject).toBe('Thunder: RSVP for vs. Eagles, Sat, Oct 24 at 10:00 AM');
    expect(email.text).toContain('Is Emma going?');
    expect(email.text).toContain('Going: https://getbattleplan.app/a/t?s=going');
    expect(email.text).toContain('Maybe: https://getbattleplan.app/a/t?s=maybe');
    expect(email.text).toContain('Not going: https://getbattleplan.app/a/t?s=not_going');
    expect(email.text).toContain("Andy Bernard sent this to everyone who hasn't RSVP'd.");
    expect(email.html).toContain('href="https://getbattleplan.app/a/t?s=going"');
    expect(email.html).toContain('Field &lt;3&gt;');
    expect(email.html).not.toContain('Field <3>');
  });

  it('asks about each player on their own, with their own buttons (PLAYER-11)', () => {
    const two = rsvpReminderEmail({
      to: 'maria@example.com',
      team: 'Thunder',
      title: 'vs. Eagles',
      when: 'Sat',
      place: '',
      asks: [
        { question: 'Is Emma going?', going: 'u?s=going&p=0', maybe: null, notGoing: 'u?s=not_going&p=0' },
        { question: 'Is Liam going?', going: 'u?s=going&p=1', maybe: null, notGoing: 'u?s=not_going&p=1' },
      ],
      sentBy: '',
      eventUrl: 'e',
    });
    expect(two.text).toContain('Is Emma going?\n\nGoing: u?s=going&p=0\nNot going: u?s=not_going&p=0');
    expect(two.text).toContain('Is Liam going?\n\nGoing: u?s=going&p=1\nNot going: u?s=not_going&p=1');
    expect(two.text).not.toContain(' and ');
    expect(two.html).toContain('href="u?s=going&amp;p=1"');
    expect(two.html.indexOf('Is Emma going?')).toBeLessThan(two.html.indexOf('href="u?s=going&amp;p=0"'));
    expect(two.html.indexOf('href="u?s=not_going&amp;p=0"')).toBeLessThan(two.html.indexOf('Is Liam going?'));
  });

  it('leaves Maybe out when the team does', () => {
    const noMaybe = rsvpReminderEmail({
      to: 'x@example.com',
      team: 'T',
      title: 'Practice',
      when: 'Tue',
      place: '',
      asks: [{ question: 'Are you going?', going: 'g', maybe: null, notGoing: 'n' }],
      sentBy: '',
      eventUrl: 'e',
    });
    expect(noMaybe.text).not.toContain('Maybe');
    expect(noMaybe.text).toContain("Your coach sent this to everyone who hasn't RSVP'd.");
  });
});

describe('the answer page', () => {
  const event = { team: 'Thunder', title: 'vs. Eagles', when: 'Sat, Oct 24 at 10:00 AM · Field 3' };

  it('asks with the tapped answer picked, a note, and Send, and never answers by itself', () => {
    const html = answerFormPage({
      event,
      rows: [{ person: emma, index: 0, picked: 'not_going', note: '' }],
      allowMaybe: true,
      answeringAs: 'Maria <Ruiz>',
      eventUrl: 'https://getbattleplan.app/app/g/thunder/schedule/e/game',
    });
    expect(html).toContain('<form method="post">');
    expect(html).toContain('<legend>Is Emma going?</legend>');
    expect(html).toContain('name="status-0" value="not_going" required checked');
    expect(html).toContain('name="status-0" value="going" required>');
    expect(html).toContain('value="maybe"');
    expect(html).toContain('>Note (optional)</label>');
    expect(html).toContain('name="note-0" maxlength="200"');
    expect(html).toContain('>Send</button>');
    expect(html).toContain('Answering as Maria &lt;Ruiz&gt;.');
    expect(html).not.toContain('class="error"');
    expect(html).not.toContain('<script');
  });

  it("asks about each player on their own, each with their own answers and note (PLAYER-11)", () => {
    const html = answerFormPage({
      event,
      rows: [
        { person: me, index: 0, picked: null, note: '' },
        { person: emma, index: 1, picked: 'maybe', note: 'Late <from> school' },
        { person: liam, index: 2, picked: 'going', note: '' },
      ],
      allowMaybe: true,
      answeringAs: 'Sam',
      eventUrl: 'e',
      error: 'Pick an answer for at least one of them, then Send.',
    });
    expect(html.match(/<fieldset>/g)).toHaveLength(3);
    expect(html).toContain('<legend>Are you going?</legend>');
    expect(html).toContain('<legend>Is Emma going?</legend>');
    expect(html).toContain('<legend>Is Liam going?</legend>');
    expect(html).not.toContain('Emma and Liam');
    // Each answers alone, so none is required.
    expect(html).not.toContain(' required');
    expect(html).toContain('id="s1-maybe" name="status-1" value="maybe" checked');
    expect(html).toContain('id="s2-going" name="status-2" value="going" checked');
    expect(html).not.toMatch(/name="status-0" value="\w+" checked/);
    expect(html).toContain('>Your note (optional)</label>');
    expect(html).toContain('>Note for Emma (optional)</label>');
    expect(html).toContain('name="note-1" maxlength="200" placeholder="Leaving at halftime">Late &lt;from&gt; school</textarea>');
    expect(html).toContain('<p class="error" role="alert">Pick an answer for at least one of them, then Send.</p>');
  });

  it('has no Maybe for a team without it', () => {
    const html = answerFormPage({
      event,
      rows: [{ person: emma, index: 0, picked: null, note: '' }],
      allowMaybe: false,
      answeringAs: 'Maria',
      eventUrl: 'e',
    });
    expect(html).not.toContain('value="maybe"');
    expect(html).not.toContain(' checked');
  });

  it('thanks them, with each answer saved and a way to change it', () => {
    const html = answeredPage({ event, answers: [{ person: emma, status: 'going' }], changeUrl: '/a/t', eventUrl: 'e' });
    expect(html).toContain('Thanks! Emma is going.');
    expect(html).toContain('href="/a/t"');
    const two = answeredPage({
      event,
      answers: [
        { person: emma, status: 'going' },
        { person: liam, status: 'not_going' },
      ],
      changeUrl: '/a/t',
      eventUrl: 'e',
    });
    expect(two).toContain('Thanks! Emma is going. Liam isn&#39;t going.');
  });

  it('explains a link that can\'t answer', () => {
    const html = answerProblemPage({ heading: 'This event was canceled', body: "There's nothing to answer.", url: 'u', label: 'Open' });
    expect(html).toContain('<h1>This event was canceled</h1>');
    expect(html).toContain('There&#39;s nothing to answer.');
  });
});

describe('answer links', () => {
  it('are 43-character secrets kept by their SHA-256, found in the path', () => {
    const token = newAnswerToken();
    expect(token).toMatch(/^[A-Za-z0-9_-]{43}$/);
    expect(answerLinkId(token)).toMatch(/^[0-9a-f]{64}$/);
    expect(answerLinkId(token)).toBe(answerLinkId(token));
    expect(answerToken(`/a/${token}`)).toBe(token);
    expect(answerToken(`/${token}`)).toBe(token);
    expect(answerToken('/a/short')).toBeNull();
    expect(answerToken(`/a/${token}/more`)).toBeNull();
  });
});

describe("who an RSVP email goes to today (today's limits, once a week)", () => {
  const DAY = 86_400_000;
  const none = { team: 0, all: 0 };
  it('everyone, the first time', () => {
    expect(planRsvpEmails(['a', 'b'], {}, none, 0)).toEqual({ send: ['a', 'b'], skipped: 0, recent: {} });
  });

  it('only people not emailed in the last week, each counted from their own email', () => {
    const emailedAt = { a: 0, b: 5 * DAY };
    expect(planRsvpEmails(['a', 'b', 'c'], emailedAt, none, 6 * DAY).send).toEqual(['c']);
    expect(() => planRsvpEmails(['a', 'b'], emailedAt, none, 6 * DAY)).toThrow('emailed-this-week');
    // A week after a's email, a is due; b, emailed later, isn't yet.
    const later = planRsvpEmails(['a', 'b'], emailedAt, none, 7 * DAY);
    expect(later).toEqual({ send: ['a'], skipped: 0, recent: { b: 5 * DAY } });
  });

  it("15 a team and 80 in all a day, whichever is less", () => {
    const want = Array.from({ length: 20 }, (_, i) => `u${i}`);
    expect(planRsvpEmails(want, {}, none, 0)).toMatchObject({ skipped: 5 });
    expect(planRsvpEmails(want, {}, none, 0).send).toHaveLength(15);
    expect(planRsvpEmails(want, {}, { team: 10, all: 0 }, 0).send).toHaveLength(5);
    expect(planRsvpEmails(want, {}, { team: 0, all: 78 }, 0).send).toEqual(['u0', 'u1']);
    expect(() => planRsvpEmails(want, {}, { team: 15, all: 0 }, 0)).toThrow('email-limit');
    expect(() => planRsvpEmails(want, {}, { team: 0, all: 80 }, 0)).toThrow('email-limit');
  });

  it('nobody to email is no error', () => {
    expect(planRsvpEmails([], {}, { team: 15, all: 80 }, 0)).toEqual({ send: [], skipped: 0, recent: {} });
  });
});
