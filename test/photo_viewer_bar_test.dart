// A photo document opens on black (DOC-4), and its bar is white on black
// in every color scheme (#71, owner's report 2026-11-20: in Light blue the
// name was navy with a white drop on the black bar, and Back hard to see).
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  final photo = Document(
    id: const DocumentId('p1'),
    groupId: const GroupId('a'),
    kind: DocumentKind.file,
    name: 'Team photo.jpg',
    path: 'groups/a/documents/p1/Team photo.jpg',
    contentType: 'image/jpeg',
    size: 1000,
    uploadedBy: 'jade',
    uploaderName: 'Jade',
    createdAt: DateTime(2026, 11),
  );

  for (final scheme in TeamScheme.values) {
    testWidgets('${scheme.value}: the name and every icon are white on the '
        'black bar', (tester) async {
      final docs = FakeDocumentRepository([photo]);
      docs.files['groups/a/documents/p1/Team photo.jpg'] = Uint8List(4);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        prefs: FakeLocalPrefs()
          ..defaultSchemeValue = scheme
          ..pushPrePromptShown = true,
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [
          testMembership(
            'a',
            'coach',
            role: MemberRole.owner,
          ).copyWith(colorScheme: scheme),
        ],
        documentRepo: docs,
      );
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/g/a/documents');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Team photo.jpg'));
      await tester.pumpAndSettle();

      final bar = find.byType(AppBar).last;
      expect(tester.widget<AppBar>(bar).backgroundColor, Colors.black);
      final name = tester.renderObject<RenderParagraph>(
        find.descendant(of: bar, matching: find.text('Team photo.jpg')),
      );
      final style = name.text.style!;
      expect(style.color, Colors.white);
      // No drop under it: the scheme's drop is for its own page.
      expect(style.shadows ?? const <Shadow>[], isEmpty);
      // Back, Download, Share, and the menu.
      final icons = find.descendant(of: bar, matching: find.byType(Icon));
      expect(icons, findsAtLeastNWidgets(3));
      for (final icon in icons.evaluate()) {
        final color = (icon.widget as Icon).color ?? IconTheme.of(icon).color;
        expect(color, Colors.white);
      }
    });
  }
}
