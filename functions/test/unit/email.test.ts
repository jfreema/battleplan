import { describe, expect, it } from 'vitest';
import { escapeHtml, layout } from '../../src/email/service.js';
import { setupEmail } from '../../src/email/templates.js';

describe('emails', () => {
  it('escape names in the HTML part', () => {
    expect(escapeHtml('<b>"Ann" & Bo</b>')).toBe('&lt;b&gt;&quot;Ann&quot; &amp; Bo&lt;/b&gt;');
    const { html, text } = layout(['Hi <you>'], { label: 'Go', url: 'https://x.test/a?b=1&c=2' });
    expect(html).toContain('Hi &lt;you&gt;');
    expect(html).toContain('https://x.test/a?b=1&amp;c=2');
    expect(text).toContain('Go: https://x.test/a?b=1&c=2');
  });

  it('builds the setup email', () => {
    const e = setupEmail('a@x.com', 'Thunder', 'Jordan', 'https://link');
    expect(e.subject).toBe('Jordan added you to Thunder on Battleplan');
    expect(e.text).toContain('https://link');
  });
});
