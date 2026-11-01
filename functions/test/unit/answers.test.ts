// Answering from an email (SPEC SCHED-14): the wording for one player,
// several, or yourself; the RSVP email with a link per answer; the answer
// page's form; and the link helpers.
import { describe, expect, it } from 'vitest';
import {
  answeredLine,
  answeredPage,
  answerFormPage,
  answerProblemPage,
  namesOf,
  questionOf,
} from '../../src/answers/page.js';
import { answerLinkId, answerToken, newAnswerToken, planRsvpEmails } from '../../src/answers/service.js';
import { rsvpReminderEmail } from '../../src/email/templates.js';

const emma = { name: 'Emma', self: false };
const liam = { name: 'Liam', self: false };
const ava = { name: 'Ava', self: false };
const me = { name: 'Sam', self: true };

describe('the wording', () => {
  it('names the players, "you" first for your own', () => {
    expect(namesOf([emma])).toBe('Emma');
    expect(namesOf([emma, liam])).toBe('Emma and Liam');
    expect(namesOf([emma, liam, ava])).toBe('Emma, Liam, and Ava');
    expect(namesOf([me])).toBe('you');
    expect(namesOf([emma, me])).toBe('you and Emma');
  });

  it('asks who is going', () => {
    expect(questionOf([emma])).toBe('Is Emma going?');
    expect(questionOf([emma, liam])).toBe('Are Emma and Liam going?');
    expect(questionOf([me])).toBe('Are you going?');
    expect(questionOf([me, emma])).toBe('Are you and Emma going?');
  });

  it('says what was saved', () => {
    expect(answeredLine([emma], 'going')).toBe('Emma is going.');
    expect(answeredLine([emma, liam], 'not_going')).toBe("Emma and Liam aren't going.");
    expect(answeredLine([me], 'going')).toBe('You are going.');
    expect(answeredLine([me, emma], 'maybe')).toBe('You and Emma might go.');
  });
});

describe('the RSVP email', () => {
  const email = rsvpReminderEmail({
    to: 'maria@example.com',
    team: 'Thunder',
    title: 'vs. Eagles',
    when: 'Sat, Oct 24 at 10:00 AM',
    place: 'Field <3>',
    question: 'Is Emma going?',
    going: 'https://getbattleplan.app/a/t?s=going',
    maybe: 'https://getbattleplan.app/a/t?s=maybe',
    notGoing: 'https://getbattleplan.app/a/t?s=not_going',
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

  it('leaves Maybe out when the team does', () => {
    const noMaybe = rsvpReminderEmail({
      to: 'x@example.com',
      team: 'T',
      title: 'Practice',
      when: 'Tue',
      place: '',
      question: 'Are you going?',
      going: 'g',
      maybe: null,
      notGoing: 'n',
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
      people: [emma, liam],
      picked: 'not_going',
      allowMaybe: true,
      answeringAs: 'Maria <Ruiz>',
      eventUrl: 'https://getbattleplan.app/app/g/thunder/schedule/e/game',
    });
    expect(html).toContain('<form method="post">');
    expect(html).toContain('Are Emma and Liam going?');
    expect(html).toContain('value="not_going" required checked');
    expect(html).toContain('value="going" required>');
    expect(html).toContain('value="maybe"');
    expect(html).toContain('maxlength="200"');
    expect(html).toContain('>Send</button>');
    expect(html).toContain('Answering as Maria &lt;Ruiz&gt;.');
    expect(html).not.toContain('<script');
  });

  it('has no Maybe for a team without it', () => {
    const html = answerFormPage({
      event,
      people: [emma],
      picked: null,
      allowMaybe: false,
      answeringAs: 'Maria',
      eventUrl: 'e',
    });
    expect(html).not.toContain('value="maybe"');
    expect(html).not.toContain(' checked');
  });

  it('thanks them, with a way to change it', () => {
    const html = answeredPage({ event, people: [emma], status: 'going', changeUrl: '/a/t?s=going', eventUrl: 'e' });
    expect(html).toContain('Thanks! Emma is going.');
    expect(html).toContain('href="/a/t?s=going"');
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
