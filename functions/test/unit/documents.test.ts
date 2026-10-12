import { describe, expect, it } from 'vitest';
import {
  documentAddedBody,
  documentFolder,
  documentRoute,
  notifiesTeam,
  orphanDocumentFiles,
} from '../../src/documents/service.js';
import { reportedBody } from '../../src/safety/service.js';

describe('documentAdded wording (DOC-6, NOTIF-5)', () => {
  it('names the file, or the link', () => {
    expect(documentAddedBody('file', 'Fall roster.pdf')).toBe('New document: Fall roster.pdf');
    expect(documentAddedBody('link', 'League site')).toBe('New link: League site');
    expect(documentAddedBody('file', '  Waiver.docx ')).toBe('New document: Waiver.docx');
  });

  it('reads anything that is not a link as a document', () => {
    expect(documentAddedBody(undefined, 'Plan')).toBe('New document: Plan');
  });

  it('routes to the document, in its own folder', () => {
    expect(documentRoute('g1', 'd1')).toBe('/g/g1/documents/d/d1');
    expect(documentFolder('g1', 'd1')).toBe('groups/g1/documents/d1/');
  });

  it('reports a document as a document', () => {
    expect(reportedBody('document')).toBe('A document was reported');
  });
});

describe('documents create trigger early exit (DOC-6)', () => {
  it('notifies unless the uploader switched Notify team off', () => {
    expect(notifiesTeam({ notifyTeam: true })).toBe(true);
    expect(notifiesTeam({})).toBe(true);
    expect(notifiesTeam({ notifyTeam: false })).toBe(false);
    expect(notifiesTeam(undefined)).toBe(false);
  });
});

describe('orphanDocumentFiles (dailyCleanup)', () => {
  const now = Date.parse('2026-10-12T12:00:00Z');
  const cutoff = now - 86_400_000;
  const old = '2026-10-10T00:00:00Z';
  const recent = '2026-10-12T11:00:00Z';
  const f = (name: string, timeCreated: unknown = old) => ({ name: `groups/g1/documents/${name}`, timeCreated });

  it('removes day-old uploads with no document, or that their document does not name', () => {
    const docs = new Map<string, string | null>([['kept', 'groups/g1/documents/kept/a.pdf']]);
    const files = [f('kept/a.pdf'), f('kept/retry.pdf'), f('gone/b.pdf'), f('new/c.pdf', recent)];
    expect(orphanDocumentFiles('g1', files, docs, cutoff)).toEqual([
      'groups/g1/documents/kept/retry.pdf',
      'groups/g1/documents/gone/b.pdf',
    ]);
  });

  it('leaves uploads younger than a day, without a time, or outside the folder', () => {
    const files = [
      f('a/x.pdf', recent),
      f('b/x.pdf', null),
      f('c/x.pdf', 'not a date'),
      { name: 'groups/g2/documents/d/x.pdf', timeCreated: old },
      { name: 'groups/g1/messages/m/x.jpg', timeCreated: old },
    ];
    expect(orphanDocumentFiles('g1', files, new Map(), cutoff)).toEqual([]);
  });
});
