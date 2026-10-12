// Documents in the app (SPEC DOC-1 to DOC-6, STORE-4, TEAM-5, TEAM-9,
// SAFE-1).
import 'package:battleplan/app/services/share_plus_sharer.dart';
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/file_chooser.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/documents/application/providers.dart';
import 'package:battleplan/features/documents/data/firestore_document_repository.dart';
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/documents/domain/document_rules.dart';
import 'package:battleplan/features/documents/presentation/add_document.dart';
import 'package:battleplan/features/documents/presentation/document_actions.dart';
import 'package:battleplan/features/documents/presentation/document_row.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/notifications/domain/notification_item.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart' show ShareResultStatus;

import 'helpers/fakes.dart';
import 'helpers/photo_fixtures.dart';
import 'helpers/pump_app.dart';

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const pdfType = 'application/pdf';
  const wordType =
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

  Document file(
    String id,
    String name, {
    String contentType = pdfType,
    String by = 'sam',
    String byName = 'Sam Rivera',
    Duration age = const Duration(days: 1),
    bool pinned = false,
    int size = 2 * bytesPerMb,
    String? fileName,
  }) => Document(
    id: DocumentId(id),
    groupId: const GroupId('a'),
    kind: DocumentKind.file,
    name: name,
    path: 'groups/a/documents/$id/${fileName ?? name}',
    contentType: contentType,
    size: size,
    uploadedBy: by,
    uploaderName: byName,
    pinned: pinned,
    createdAt: DateTime.now().subtract(age),
  );

  Document link(
    String id,
    String name,
    String url, {
    String by = 'sam',
    Duration age = const Duration(days: 1),
    bool pinned = false,
  }) => Document(
    id: DocumentId(id),
    groupId: const GroupId('a'),
    kind: DocumentKind.link,
    name: name,
    url: url,
    uploadedBy: by,
    uploaderName: 'Sam Rivera',
    pinned: pinned,
    createdAt: DateTime.now().subtract(age),
  );

  /// Fall roster (Sam, 3 days), Playbook (mine, a day), Team photo (Pat,
  /// 2 hours), and the League site link, pinned and oldest.
  List<Document> teamDocs() => [
    file('roster', 'Fall roster.pdf', age: const Duration(days: 3)),
    file(
      'playbook',
      'Playbook.docx',
      contentType: wordType,
      by: 'coach',
      byName: 'Coach Lee',
    ),
    file(
      'photo',
      'Team photo.jpg',
      contentType: 'image/jpeg',
      by: 'pat',
      byName: 'Pat Kim',
      age: const Duration(hours: 2),
    ),
    link(
      'league',
      'League site',
      'https://league.example.com/fall',
      age: const Duration(days: 10),
      pinned: true,
    ),
  ];

  group('document rules of thumb', () {
    test('file types: allowed extensions and how they show (DOC-2)', () {
      expect(contentTypeForFile('Roster.PDF'), pdfType);
      expect(contentTypeForFile('notes.docx'), wordType);
      expect(contentTypeForFile('list.csv'), 'text/csv');
      expect(contentTypeForFile('photo.heic'), 'image/heic');
      expect(contentTypeForFile('setup.exe'), isNull);
      expect(contentTypeForFile('README'), isNull);
      expect(contentTypeForFile('trailing.'), isNull);

      expect(documentTypeOf(pdfType), DocumentType.pdf);
      expect(documentTypeOf('image/png'), DocumentType.image);
      expect(documentTypeOf(wordType), DocumentType.word);
      expect(documentTypeOf('application/vnd.ms-excel'), DocumentType.excel);
      expect(
        documentTypeOf(
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        ),
        DocumentType.powerpoint,
      );
      expect(documentTypeOf('text/plain'), DocumentType.text);
      expect(documentTypeOf('text/csv'), DocumentType.csv);
      expect(documentTypeOf(null), DocumentType.other);

      final pdf = file('r', 'Roster', fileName: 'Fall roster.pdf');
      expect(pdf.opensInApp, isTrue);
      // Renamed, it still shares and saves as its stored file.
      expect(pdf.fileName, 'Fall roster.pdf');
      expect(file('p', 'P.docx', contentType: wordType).opensInApp, isFalse);
      expect(link('l', 'L', 'https://x.com').type, DocumentType.link);
      expect(link('l', 'L', 'https://x.com').fileName, 'L');
    });

    test('HEIC and HEIF photos open in the viewer except on the web '
        '(DOC-4)', () {
      final heic = file('h', 'IMG_1.heic', contentType: 'image/heic');
      final heif = file('f', 'IMG_2.heif', contentType: 'image/heif');
      final jpeg = file('j', 'Photo.jpg', contentType: 'image/jpeg');
      expect(heic.opensInAppOn(web: false), isTrue);
      expect(heic.opensInAppOn(web: true), isFalse);
      expect(heif.opensInAppOn(web: true), isFalse);
      expect(jpeg.opensInAppOn(web: true), isTrue);
      expect(file('p', 'P.pdf').opensInAppOn(web: true), isTrue);
    });

    test('Web Share counts as shared even when share_plus says '
        'unavailable (DOC-4)', () {
      // share_plus says unavailable on the web after Web Share or its
      // download fallback worked.
      expect(sharedFrom(ShareResultStatus.unavailable, web: true), isTrue);
      expect(sharedFrom(ShareResultStatus.success, web: true), isTrue);
      // On phones it means there's no share sheet.
      expect(sharedFrom(ShareResultStatus.unavailable, web: false), isFalse);
      expect(sharedFrom(ShareResultStatus.success, web: false), isTrue);
      expect(sharedFrom(ShareResultStatus.dismissed, web: false), isTrue);
    });

    test('links are http or https with a host (DOC-3)', () {
      expect(
        parseDocumentUrl(' https://league.example.com/a?b=1 ').toString(),
        'https://league.example.com/a?b=1',
      );
      expect(
        parseDocumentUrl('http://example.com').toString(),
        'http://example.com',
      );
      // A bare address gets https.
      expect(
        parseDocumentUrl('forms.example.com/signup').toString(),
        'https://forms.example.com/signup',
      );
      expect(parseDocumentUrl(''), isNull);
      expect(parseDocumentUrl('not a link'), isNull);
      expect(parseDocumentUrl('ftp://example.com/file'), isNull);
      expect(parseDocumentUrl('javascript:alert(1)'), isNull);
      expect(parseDocumentUrl('https://nodot'), isNull);
      expect(parseDocumentUrl('https://example.com/${'a' * 2000}'), isNull);
    });

    test('names up to 100 characters, descriptions up to 500', () {
      expect(isValidDocumentName(' Roster '), isTrue);
      expect(isValidDocumentName('   '), isFalse);
      expect(isValidDocumentName('x' * 100), isTrue);
      expect(isValidDocumentName('x' * 101), isFalse);
      expect(isValidDocumentDescription(''), isTrue);
      expect(isValidDocumentDescription('x' * 500), isTrue);
      expect(isValidDocumentDescription('x' * 501), isFalse);
    });

    test('pinned first, then newest or by name, filtered (DOC-1)', () {
      List<String> names(DocumentSort sort, [String filter = '']) => [
        for (final d in arrangeDocuments(
          teamDocs(),
          sort: sort,
          filter: filter,
        ))
          d.name,
      ];
      expect(names(DocumentSort.recent), [
        'League site',
        'Team photo.jpg',
        'Playbook.docx',
        'Fall roster.pdf',
      ]);
      expect(names(DocumentSort.name), [
        'League site',
        'Fall roster.pdf',
        'Playbook.docx',
        'Team photo.jpg',
      ]);
      expect(names(DocumentSort.name, ' PLAY '), ['Playbook.docx']);
      expect(names(DocumentSort.recent, 'zzz'), isEmpty);
    });

    test('Storage file names stay one safe path segment', () {
      expect(storageFileName('Fall roster.pdf'), 'Fall roster.pdf');
      expect(storageFileName(r'a/b\c#d.pdf'), 'a_b_c_d.pdf');
      expect(storageFileName('..'), 'file');
      final long = storageFileName('${'x' * 120}.xlsx');
      expect(long.length, 100);
      expect(long, endsWith('.xlsx'));
    });

    test('who may add, manage, pin, delete, and report (DOC-5, TEAM-5, '
        'TEAM-9)', () {
      final team = testGroup('a', 'Thunder');
      final closed = team.copyWith(
        settings: const GroupSettings(membersCanUploadDocs: false),
      );
      final archived = team.copyWith(archivedAt: DateTime(2026));
      final admin = testMembership('a', 'coach', role: MemberRole.admin);
      final member = testMembership('a', 'coach');
      final mine = file('p', 'Mine', by: 'coach');
      final theirs = file('r', 'Theirs');

      expect(canAddDocuments(team, member), isTrue);
      expect(canAddDocuments(closed, member), isFalse);
      expect(canAddDocuments(closed, admin), isTrue);
      expect(canAddDocuments(archived, admin), isFalse);
      expect(canAddDocuments(team, null), isFalse);

      expect(canManageDocument(mine, team, member), isTrue);
      expect(canManageDocument(theirs, team, member), isFalse);
      expect(canManageDocument(theirs, team, admin), isTrue);
      expect(canManageDocument(mine, archived, member), isFalse);
      expect(canDeleteDocument(theirs, team, member, superAdmin: true), isTrue);
      expect(
        canDeleteDocument(theirs, archived, admin, superAdmin: true),
        isFalse,
      );

      expect(canPinDocument(team, admin), isTrue);
      expect(canPinDocument(team, member), isFalse);
      expect(canPinDocument(archived, admin), isFalse);

      expect(canReportDocument(theirs, member), isTrue);
      expect(canReportDocument(mine, member), isFalse);

      expect(documentActions(theirs, team, member), [
        DocumentAction.open,
        DocumentAction.share,
        DocumentAction.download,
        DocumentAction.details,
        DocumentAction.report,
      ]);
      expect(documentActions(mine, team, member), [
        DocumentAction.open,
        DocumentAction.share,
        DocumentAction.download,
        DocumentAction.details,
        DocumentAction.edit,
        DocumentAction.delete,
      ]);
      expect(
        documentActions(
          link('l', 'L', 'https://x.com'),
          team,
          admin,
          inViewer: true,
        ),
        [
          DocumentAction.edit,
          DocumentAction.pin,
          DocumentAction.delete,
          DocumentAction.report,
        ],
      );
    });

    test('dates: time today, month and day this year, then the year', () {
      final now = DateTime(2026, 10, 12, 18);
      // intl puts a narrow no-break space before AM and PM.
      expect(documentDate(DateTime(2026, 10, 12, 14, 15), now), '2:15 PM');
      expect(documentDate(DateTime(2026, 10, 6), now), 'Oct 6');
      expect(documentDate(DateTime(2025, 10, 6), now), 'Oct 6, 2025');
      expect(documentDate(null, now), '');
    });
  });

  group('the documents tab', () {
    Future<
      ({
        FakeDocumentRepository docs,
        FakeFileChooser chooser,
        FakeSharer sharer,
        FakeLinkOpener opener,
        FakeSafetyRepository safety,
      })
    >
    openDocuments(
      WidgetTester tester, {
      List<Document>? docs,
      MemberRole role = MemberRole.member,
      GroupSettings settings = const GroupSettings(),
      bool storageFull = false,
      bool archived = false,
      FakeFileChooser? chooser,
      Map<String, Uint8List> files = const {},
      FakeNotificationRepository? notifications,
      FakeGroupRepository? groupRepo,
      bool tapDocuments = true,
    }) async {
      final repo = FakeDocumentRepository(docs ?? teamDocs());
      repo.files.addAll(files);
      final fileChooser = chooser ?? FakeFileChooser();
      final sharer = FakeSharer();
      final opener = FakeLinkOpener();
      final safety = FakeSafetyRepository();
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {
          'a': testGroup('a', 'Thunder').copyWith(
            settings: settings,
            storageBytes: storageFull ? 500 * bytesPerMb : 0,
            storageQuotaBytes: 500 * bytesPerMb,
            archivedAt: archived ? DateTime(2026) : null,
          ),
        },
        memberships: [
          testMembership('a', 'coach', role: role, name: 'Coach Lee'),
          testMembership('a', 'sam', name: 'Sam Rivera'),
          testMembership('a', 'pat', name: 'Pat Kim'),
        ],
        groupRepo: groupRepo,
        documentRepo: repo,
        fileChooser: fileChooser,
        sharer: sharer,
        linkOpener: opener,
        safety: safety,
        notifications: notifications,
      );
      if (tapDocuments) {
        await tester.tap(find.text('Documents'));
        await tester.pumpAndSettle();
      }
      return (
        docs: repo,
        chooser: fileChooser,
        sharer: sharer,
        opener: opener,
        safety: safety,
      );
    }

    Finder rowOf(String name) =>
        find.ancestor(of: find.text(name), matching: find.byType(DocumentRow));

    /// Opens [name]'s ⋯ menu and picks [item].
    Future<void> menu(WidgetTester tester, String name, String item) async {
      await tester.tap(
        find.descendant(
          of: rowOf(name),
          matching: find.byTooltip('Document actions'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(item).last);
      await tester.pumpAndSettle();
    }

    /// The labels in [name]'s ⋯ menu, which it then closes.
    Future<List<String>> menuItems(WidgetTester tester, String name) async {
      await tester.tap(
        find.descendant(
          of: rowOf(name),
          matching: find.byTooltip('Document actions'),
        ),
      );
      await tester.pumpAndSettle();
      final items = [
        for (final t in tester.widgetList<Text>(
          find.descendant(
            of: find.byType(PopupMenuItem<DocumentAction>),
            matching: find.byType(Text),
          ),
        ))
          t.data!,
      ];
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      return items;
    }

    List<String> rowOrder(WidgetTester tester) {
      final rows = tester.widgetList<DocumentRow>(find.byType(DocumentRow));
      return [for (final r in rows) r.doc.name];
    }

    testWidgets('pinned first, then Recent or Name, with who and how big '
        '(DOC-1)', (tester) async {
      await openDocuments(tester);
      expect(rowOrder(tester), [
        'League site',
        'Team photo.jpg',
        'Playbook.docx',
        'Fall roster.pdf',
      ]);
      expect(
        find.descendant(
          of: rowOf('League site'),
          matching: find.byIcon(AppIcons.pin),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('2.0 MB · Sam Rivera · '), findsOneWidget);
      expect(
        find.textContaining('league.example.com · Sam Rivera'),
        findsOneWidget,
      );
      expect(find.textContaining('Pat Kim'), findsOneWidget);

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(rowOrder(tester), [
        'League site',
        'Fall roster.pdf',
        'Playbook.docx',
        'Team photo.jpg',
      ]);
    });

    testWidgets('typing filters by name', (tester) async {
      await openDocuments(tester);
      await tester.enterText(find.byType(TextField), 'ROST');
      await tester.pumpAndSettle();
      expect(rowOrder(tester), ['Fall roster.pdf']);
      await tester.enterText(find.byType(TextField), 'zebra');
      await tester.pumpAndSettle();
      expect(rowOrder(tester), isEmpty);
      expect(find.text('No documents match "zebra".'), findsOneWidget);
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
      expect(rowOrder(tester), hasLength(4));
    });

    testWidgets('an empty team says what goes here', (tester) async {
      await openDocuments(tester, docs: []);
      expect(
        find.text('Share schedules, forms, and playbooks with your team.'),
        findsOneWidget,
      );
      // Members may add by default (TEAM-5).
      expect(find.byTooltip('Add a file or link'), findsOneWidget);
    });

    testWidgets('more than 100 load a page at a time', (tester) async {
      await openDocuments(
        tester,
        docs: [
          for (var i = 0; i < 150; i++)
            file(
              'd$i',
              'Doc ${i.toString().padLeft(3, '0')}',
              age: Duration(minutes: i),
            ),
        ],
      );
      expect(find.byType(DocumentRow), findsWidgets);
      final list = find
          .ancestor(
            of: find.byType(DocumentRow).first,
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Load more'),
        500,
        scrollable: list,
      );
      expect(find.text('Doc 099'), findsOneWidget);
      expect(find.text('Doc 100'), findsNothing);
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Doc 149'),
        500,
        scrollable: list,
      );
      expect(find.text('Doc 149'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
    });

    testWidgets('documents from Load more follow deletes and edits '
        '(DOC-5)', (tester) async {
      final r = await openDocuments(
        tester,
        role: MemberRole.admin,
        docs: [
          for (var i = 0; i < 150; i++)
            file(
              'd$i',
              'Doc ${i.toString().padLeft(3, '0')}',
              age: Duration(minutes: i),
            ),
        ],
      );
      final list = find
          .ancestor(
            of: find.byType(DocumentRow).first,
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Load more'),
        500,
        scrollable: list,
      );
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      List<String> listed() => [
        for (final d
            in ProviderScope.containerOf(
                  tester.element(find.byType(DocumentRow).first),
                )
                .read(
                  teamDocumentsProvider(
                    const GroupId('a'),
                    DocumentSort.recent,
                  ),
                )
                .documents)
          d.name,
      ];
      expect(listed(), hasLength(150));

      // Deleted from its menu, the row goes at once.
      await tester.scrollUntilVisible(
        find.text('Doc 120'),
        500,
        scrollable: list,
      );
      await menu(tester, 'Doc 120', 'Delete');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(r.docs.deleted, ['d120']);
      expect(find.text('Doc 120'), findsNothing);
      expect(listed(), isNot(contains('Doc 120')));

      // Another member renames one and deletes another.
      r.docs.put(r.docs.docs['d130']!.copyWith(name: 'Renamed 130'));
      await r.docs.delete(r.docs.docs['d140']!);
      await tester.pumpAndSettle();
      expect(listed(), contains('Renamed 130'));
      expect(listed(), isNot(contains('Doc 130')));
      expect(listed(), isNot(contains('Doc 140')));
      expect(listed(), hasLength(148));
    });

    group('uploading (DOC-2)', () {
      Future<FakeDocumentRepository> startUpload(
        WidgetTester tester,
        PickedFile picked,
      ) async {
        final r = await openDocuments(
          tester,
          docs: [],
          chooser: FakeFileChooser(next: picked),
        );
        await tester.tap(find.byTooltip('Add a file or link'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Upload file'));
        await tester.pumpAndSettle();
        expect(r.chooser.extensions, containsAll(['pdf', 'docx', 'csv']));
        return r.docs;
      }

      Finder formField(int i) => find
          .descendant(
            of: find.byType(UploadForm),
            matching: find.byType(TextField),
          )
          .at(i);

      testWidgets('rename, describe, progress, then it lists', (tester) async {
        final docs = await startUpload(
          tester,
          pickedFile('scan_0042.pdf', 3 * bytesPerMb),
        );
        expect(find.text('scan_0042.pdf · 3.0 MB'), findsOneWidget);
        // The name starts as the file's; empty isn't allowed.
        expect(find.text('scan_0042.pdf'), findsOneWidget);
        await tester.enterText(formField(0), '  ');
        await tester.pump();
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Upload'))
              .onPressed,
          isNull,
        );
        await tester.enterText(formField(0), 'Fall roster');
        await tester.enterText(formField(1), 'Updated Oct 1');
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Upload'));
        await tester.pump();
        await tester.pump();

        final upload = docs.upload!..report(0.42);
        await tester.pump();
        expect(find.text('Uploading… 42%'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        upload.finish();
        await tester.pumpAndSettle();
        expect(find.text('Uploaded.'), findsOneWidget);
        final created = docs.docs.values.single;
        expect(created.name, 'Fall roster');
        expect(created.description, 'Updated Oct 1');
        expect(created.contentType, pdfType);
        expect(created.size, 3 * bytesPerMb);
        expect(created.path, 'groups/a/documents/new0/scan_0042.pdf');
        // Notify team is on unless turned off (DOC-6).
        expect(docs.notified['new0'], isTrue);
        expect(find.text('Fall roster'), findsOneWidget);
      });

      testWidgets('Notify team can be turned off', (tester) async {
        final docs = await startUpload(tester, pickedFile('Notes.txt', 100));
        await tester.tap(find.text('Notify team'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Upload'));
        await tester.pump();
        await tester.pump();
        docs.upload!.finish();
        await tester.pumpAndSettle();
        expect(docs.notified.values.single, isFalse);
        expect(docs.docs.values.single.contentType, 'text/plain');
      });

      testWidgets('a JPEG uploads without its location (Privacy Policy)', (
        tester,
      ) async {
        final photo = jpegWith([exifSegment()]);
        final docs = await startUpload(tester, (
          name: 'IMG_0042.jpg',
          size: photo.length,
          readBytes: () async => photo,
        ));
        await tester.tap(find.widgetWithText(FilledButton, 'Upload'));
        await tester.pump();
        await tester.pump();
        docs.upload!.finish();
        await tester.pumpAndSettle();
        final stored = docs.files.values.single;
        expect(indexOfBytes(photo, gpsLatitude), isNot(-1));
        expect(indexOfBytes(stored, gpsLatitude), -1);
        expect(readIfd(exifTiff(stored)!, 8).$1.keys, isNot(contains(0x8825)));
        // Same orientation, same image data.
        expect(readIfd(exifTiff(stored)!, 8).$1[0x0112], 6);
        expect(imageData(stored), imageData(photo));
      });

      testWidgets('Cancel stops it, and nothing is added', (tester) async {
        final docs = await startUpload(tester, pickedFile('Big.pdf', 9000000));
        await tester.tap(find.widgetWithText(FilledButton, 'Upload'));
        await tester.pump();
        await tester.pump();
        docs.upload!.report(0.1);
        await tester.pump();
        await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
        await tester.pumpAndSettle();
        expect(docs.upload!.canceled, isTrue);
        expect(find.text('Upload canceled.'), findsOneWidget);
        expect(docs.docs, isEmpty);
        // It can start again.
        expect(find.widgetWithText(FilledButton, 'Upload'), findsOneWidget);
      });

      testWidgets('a failed upload says so', (tester) async {
        final docs = await startUpload(tester, pickedFile('Big.pdf', 1000));
        await tester.tap(find.widgetWithText(FilledButton, 'Upload'));
        await tester.pump();
        await tester.pump();
        docs.upload!.fail(const PermissionDenied('storage'));
        await tester.pumpAndSettle();
        expect(
          find.text("You can't upload documents to this team."),
          findsOneWidget,
        );
        expect(docs.docs, isEmpty);
      });

      testWidgets('storage filling up while the form is open says so '
          '(STORE-4)', (tester) async {
        final groups = FakeGroupRepository({
          'a': testGroup(
            'a',
            'Thunder',
          ).copyWith(storageQuotaBytes: 500 * bytesPerMb),
        });
        final r = await openDocuments(
          tester,
          docs: [],
          groupRepo: groups,
          chooser: FakeFileChooser(next: pickedFile('Big.pdf', 1000)),
        );
        await tester.tap(find.byTooltip('Add a file or link'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Upload file'));
        await tester.pumpAndSettle();
        // Another member's upload fills it.
        groups.setGroup(
          groups.groups['a']!.copyWith(storageBytes: 500 * bytesPerMb),
        );
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Upload'));
        await tester.pump();
        await tester.pump();
        r.docs.upload!.fail(const PermissionDenied('storage'));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(UploadForm),
            matching: find.textContaining('Storage is full.'),
          ),
          findsOneWidget,
        );
        expect(
          find.text("You can't upload documents to this team."),
          findsNothing,
        );
      });

      testWidgets('over 10 MB is refused before the form', (tester) async {
        final docs = await startUpload(
          tester,
          pickedFile('Video.pdf', 11 * bytesPerMb),
        );
        expect(
          find.text('That file is 11 MB. Files can be up to 10 MB.'),
          findsOneWidget,
        );
        expect(find.byType(UploadForm), findsNothing);
        expect(docs.upload, isNull);
      });

      testWidgets('other types are refused', (tester) async {
        await startUpload(tester, pickedFile('setup.exe', 100));
        expect(
          find.textContaining("That type of file can't be uploaded."),
          findsOneWidget,
        );
        expect(find.byType(UploadForm), findsNothing);
      });
    });

    testWidgets('full storage turns off uploads but not links (STORE-4)', (
      tester,
    ) async {
      final r = await openDocuments(
        tester,
        docs: [],
        storageFull: true,
        chooser: FakeFileChooser(next: pickedFile('a.pdf', 10)),
      );
      await tester.tap(find.byTooltip('Add a file or link'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upload file'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('Storage is full.'),
        ),
        findsOneWidget,
      );
      // The picker never opened.
      expect(r.chooser.extensions, isEmpty);
      // The message goes away.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add a file or link'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add link'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'example.com/form');
      await tester.enterText(find.byType(TextField).at(2), 'Sign-up form');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Add link'));
      await tester.pumpAndSettle();
      expect(find.text('Link added.'), findsOneWidget);
      expect(r.docs.docs.values.single.url, 'https://example.com/form');
    });

    testWidgets('a link needs a name and an http or https address (DOC-3)', (
      tester,
    ) async {
      final r = await openDocuments(tester, docs: []);
      await tester.tap(find.byTooltip('Add a file or link'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add link'));
      await tester.pumpAndSettle();
      FilledButton add() =>
          tester.widget(find.widgetWithText(FilledButton, 'Add link'));
      Finder field(int i) => find.byType(TextField).at(i + 1);
      expect(add().onPressed, isNull);

      await tester.enterText(field(0), 'ftp://example.com/file');
      await tester.enterText(field(1), 'League site');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Add link'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a web address that starts with http:// or https://.'),
        findsOneWidget,
      );
      expect(r.docs.docs, isEmpty);

      await tester.enterText(field(0), 'not a link');
      await tester.tap(find.widgetWithText(FilledButton, 'Add link'));
      await tester.pumpAndSettle();
      expect(r.docs.docs, isEmpty);

      await tester.enterText(field(0), 'https://league.example.com');
      await tester.enterText(field(2), 'Standings and fields');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Add link'));
      await tester.pumpAndSettle();
      final added = r.docs.docs.values.single;
      expect(added.kind, DocumentKind.link);
      expect(added.name, 'League site');
      expect(added.url, 'https://league.example.com');
      expect(added.description, 'Standings and fields');
      expect(r.docs.notified.values.single, isTrue);
      expect(find.text('League site'), findsOneWidget);
    });

    group('opening (DOC-4)', () {
      final pdfBytes = Uint8List.fromList(List.filled(1234, 1));
      final wordBytes = Uint8List.fromList(List.filled(10, 2));

      testWidgets('a link opens in the browser', (tester) async {
        final r = await openDocuments(tester);
        await tester.tap(find.text('League site'));
        await tester.pumpAndSettle();
        expect(r.opener.opened, [Uri.parse('https://league.example.com/fall')]);
      });

      testWidgets('a PDF opens in the viewer, with Share and Download', (
        tester,
      ) async {
        final r = await openDocuments(
          tester,
          files: {'groups/a/documents/roster/Fall roster.pdf': pdfBytes},
        );
        await tester.tap(find.text('Fall roster.pdf'));
        await tester.pumpAndSettle();
        expect(find.text('PDF Fall roster.pdf (1234 bytes)'), findsOneWidget);

        await tester.tap(find.byTooltip('Share'));
        await tester.pumpAndSettle();
        expect(r.sharer.shared, ['file Fall roster.pdf $pdfType']);
        await tester.tap(find.byTooltip('Download'));
        await tester.pumpAndSettle();
        expect(r.chooser.saved, ['Fall roster.pdf']);
        expect(find.text('Downloaded.'), findsOneWidget);
      });

      testWidgets('an image opens zoomable', (tester) async {
        await openDocuments(
          tester,
          files: {
            'groups/a/documents/photo/Team photo.jpg': Uint8List.fromList([0]),
          },
        );
        await tester.tap(find.text('Team photo.jpg'));
        await tester.pumpAndSettle();
        expect(find.byType(InteractiveViewer), findsOneWidget);
      });

      testWidgets("an image that can't be decoded says to download it", (
        tester,
      ) async {
        await openDocuments(
          tester,
          files: {
            'groups/a/documents/photo/Team photo.jpg': Uint8List.fromList([0]),
          },
        );
        await tester.tap(find.text('Team photo.jpg'));
        await tester.pumpAndSettle();
        // Decoding runs outside the fake clock.
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
        }
        expect(
          find.text(
            "Couldn't show this image. Download it to open it in another "
            'app.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('HEIC photos download in the browser', (tester) async {
        final heic = Uint8List.fromList([0, 0, 0]);
        final r = await openDocuments(
          tester,
          chooser: FakeFileChooser(web: true),
          docs: [file('heic', 'IMG_0042.heic', contentType: 'image/heic')],
          files: {'groups/a/documents/heic/IMG_0042.heic': heic},
        );
        await tester.tap(find.text('IMG_0042.heic'));
        await tester.pumpAndSettle();
        expect(find.byType(InteractiveViewer), findsNothing);
        expect(r.chooser.saved, ['IMG_0042.heic']);

        // A notification lands on its details, with Open.
        GoRouter.of(tester.element(find.byType(DocumentRow).first))
            .go('/g/a/documents/d/heic');
        await tester.pumpAndSettle();
        expect(find.byType(InteractiveViewer), findsNothing);
        expect(find.text('Open'), findsOneWidget);
      });

      testWidgets('other files open in the default app on phones', (
        tester,
      ) async {
        final r = await openDocuments(
          tester,
          files: {'groups/a/documents/playbook/Playbook.docx': wordBytes},
        );
        await tester.tap(find.text('Playbook.docx'));
        await tester.pumpAndSettle();
        expect(r.opener.opened, [
          Uri.parse(
            'https://files.test/groups/a/documents/playbook/'
            'Playbook.docx',
          ),
        ]);
        expect(r.chooser.saved, isEmpty);
      });

      testWidgets('and download in the browser', (tester) async {
        final r = await openDocuments(
          tester,
          chooser: FakeFileChooser(web: true),
          files: {'groups/a/documents/playbook/Playbook.docx': wordBytes},
        );
        await tester.tap(find.text('Playbook.docx'));
        await tester.pumpAndSettle();
        expect(r.opener.opened, isEmpty);
        expect(r.chooser.saved, ['Playbook.docx']);
        expect(find.text('Downloaded.'), findsOneWidget);
      });

      testWidgets('Share and Download from the menu', (tester) async {
        final r = await openDocuments(
          tester,
          files: {'groups/a/documents/playbook/Playbook.docx': wordBytes},
        );
        await menu(tester, 'League site', 'Share');
        expect(r.sharer.shared, ['link https://league.example.com/fall']);
        await menu(tester, 'Playbook.docx', 'Share');
        expect(r.sharer.shared.last, 'file Playbook.docx $wordType');
        await menu(tester, 'Playbook.docx', 'Download');
        expect(r.chooser.saved, ['Playbook.docx']);
        // A file that can't be read says so.
        await menu(tester, 'Fall roster.pdf', 'Download');
        expect(
          find.text(
            "Couldn't download this. Check your connection and try "
            'again.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('Details shows who added it and the description', (
        tester,
      ) async {
        await openDocuments(
          tester,
          docs: [
            file(
              'playbook',
              'Playbook.docx',
              contentType: wordType,
            ).copyWith(description: 'Set plays for the fall'),
          ],
        );
        await menu(tester, 'Playbook.docx', 'Details');
        expect(find.textContaining('Added by Sam Rivera · '), findsOneWidget);
        expect(find.text('Set plays for the fall'), findsOneWidget);
        expect(find.text('Open'), findsOneWidget);
      });
    });

    group('managing (DOC-5)', () {
      testWidgets('members manage only their own, and report others', (
        tester,
      ) async {
        await openDocuments(tester);
        expect(await menuItems(tester, 'Fall roster.pdf'), [
          'Open',
          'Share',
          'Download',
          'Details',
          'Report',
        ]);
        expect(await menuItems(tester, 'Playbook.docx'), [
          'Open',
          'Share',
          'Download',
          'Details',
          'Rename or edit description',
          'Delete',
        ]);
      });

      testWidgets('admins manage, pin, and delete anything', (tester) async {
        final r = await openDocuments(tester, role: MemberRole.admin);
        expect(await menuItems(tester, 'Fall roster.pdf'), [
          'Open',
          'Share',
          'Download',
          'Details',
          'Rename or edit description',
          'Pin',
          'Delete',
          'Report',
        ]);
        expect(await menuItems(tester, 'League site'), contains('Unpin'));

        await menu(tester, 'Fall roster.pdf', 'Pin');
        expect(find.text('Pinned to the top.'), findsOneWidget);
        expect(r.docs.docs['roster']!.pinned, isTrue);
        expect(rowOrder(tester).take(2), ['Fall roster.pdf', 'League site']);
        await menu(tester, 'League site', 'Unpin');
        expect(r.docs.docs['league']!.pinned, isFalse);
        expect(rowOrder(tester).last, 'League site');

        await menu(tester, 'Fall roster.pdf', 'Delete');
        expect(find.text('Delete "Fall roster.pdf"?'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await tester.pumpAndSettle();
        expect(r.docs.deleted, ['roster']);
        expect(find.text('Fall roster.pdf'), findsNothing);
      });

      testWidgets('the uploader renames and edits the description', (
        tester,
      ) async {
        final r = await openDocuments(tester);
        await menu(tester, 'Playbook.docx', 'Rename or edit description');
        expect(find.text('Edit document'), findsOneWidget);
        await tester.enterText(find.byType(TextField).at(1), 'Fall playbook');
        await tester.enterText(find.byType(TextField).at(2), 'Version 2');
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();
        expect(r.docs.docs['playbook']!.name, 'Fall playbook');
        expect(r.docs.docs['playbook']!.description, 'Version 2');
        expect(find.text('Fall playbook'), findsOneWidget);
      });

      testWidgets('deleting can be canceled', (tester) async {
        final r = await openDocuments(tester);
        await menu(tester, 'Playbook.docx', 'Delete');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(r.docs.deleted, isEmpty);
        expect(find.text('Playbook.docx'), findsOneWidget);
      });

      testWidgets('reporting a document (SAFE-1)', (tester) async {
        final r = await openDocuments(tester);
        await menu(tester, 'Fall roster.pdf', 'Report');
        await tester.tap(find.text('Spam'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Send report'));
        await tester.pumpAndSettle();
        expect(r.safety.reports, ['document roster spam']);
      });
    });

    testWidgets('with membersCanUploadDocs off only admins add (TEAM-5)', (
      tester,
    ) async {
      const closed = GroupSettings(membersCanUploadDocs: false);
      await openDocuments(tester, settings: closed);
      expect(find.byTooltip('Add a file or link'), findsNothing);
      await openDocuments(tester, settings: closed, role: MemberRole.admin);
      expect(find.byTooltip('Add a file or link'), findsOneWidget);
    });

    testWidgets('archived teams are read-only (TEAM-9)', (tester) async {
      final r = await openDocuments(
        tester,
        role: MemberRole.admin,
        archived: true,
      );
      expect(
        find.text('This team is archived. Documents are read-only.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Add a file or link'), findsNothing);
      final items = await menuItems(tester, 'Playbook.docx');
      expect(items, ['Open', 'Share', 'Download', 'Details']);
      // Opening still works.
      await tester.tap(find.text('League site'));
      await tester.pumpAndSettle();
      expect(r.opener.opened, hasLength(1));
    });

    testWidgets('a notification opens the document (NOTIF-6)', (tester) async {
      final notifications = FakeNotificationRepository([
        NotificationItem(
          id: 'roster_added_coach',
          groupId: const GroupId('a'),
          kind: NotifyKind.documentAdded,
          title: 'Thunder',
          body: 'New document: Fall roster.pdf',
          route: '/g/a/documents/d/roster',
          actorId: 'sam',
          createdAt: DateTime.now(),
        ),
        NotificationItem(
          id: 'gone_added_coach',
          groupId: const GroupId('a'),
          kind: NotifyKind.documentAdded,
          title: 'Thunder',
          body: 'New document: Old.pdf',
          route: '/g/a/documents/d/gone',
          actorId: 'sam',
          createdAt: DateTime.now(),
        ),
      ]);
      await openDocuments(
        tester,
        notifications: notifications,
        tapDocuments: false,
        files: {
          'groups/a/documents/roster/Fall roster.pdf': Uint8List.fromList([1]),
        },
      );
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New document: Fall roster.pdf'));
      await tester.pumpAndSettle();
      expect(find.text('PDF Fall roster.pdf (1 bytes)'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New document: Old.pdf'));
      await tester.pumpAndSettle();
      expect(find.text('This document was deleted.'), findsOneWidget);
    });

    testWidgets('a deleted document leaves its viewer', (tester) async {
      final r = await openDocuments(
        tester,
        role: MemberRole.admin,
        files: {
          'groups/a/documents/roster/Fall roster.pdf': Uint8List.fromList([1]),
        },
      );
      await tester.tap(find.text('Fall roster.pdf'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Document actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(r.docs.deleted, ['roster']);
      expect(rowOrder(tester), hasLength(3));
    });
  });
}
