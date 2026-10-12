// The Chat tab's phone layout (SPEC §5.4): the composer names the team,
// and the header shows my photo. The event card's answer buttons are in
// schedule_test.dart.
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/auth/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

/// A profile with a photo.
class _PhotoUsers extends FakeUserRepository {
  @override
  Stream<UserProfile?> watchProfile(String uid) => super
      .watchProfile(uid)
      .map((p) => p?.copyWith(photoPath: 'users/$uid/photo.jpg'));

  @override
  Future<String?> photoUrl(String path) async => 'https://files.test/$path';
}

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
    displayName: 'Coach Lee',
  );

  Future<void> openChat(WidgetTester tester, {FakeUserRepository? users}) =>
      pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {'a': testGroup('a', 'Thunder U14')},
        memberships: [testMembership('a', 'coach', name: 'Coach Lee')],
        users: users,
      );

  testWidgets('the composer says "Message Thunder U14…"', (tester) async {
    await openChat(tester);
    final field = tester.widget<TextField>(find.byType(TextField).last);
    expect(field.decoration?.hintText, 'Message Thunder U14…');
  });

  testWidgets('the header shows my photo', (tester) async {
    await openChat(tester, users: _PhotoUsers());
    await tester.pumpAndSettle();
    final mine = tester
        .widgetList<Avatar>(find.byType(Avatar))
        .where((a) => a.colorKey == 'coach');
    expect(
      mine.map((a) => a.imageUrl),
      contains('https://files.test/users/coach/photo.jpg'),
    );
  });

  testWidgets('initials without a photo', (tester) async {
    await openChat(tester);
    final mine = tester
        .widgetList<Avatar>(find.byType(Avatar))
        .where((a) => a.colorKey == 'coach');
    expect(mine, isNotEmpty);
    expect(mine.every((a) => a.imageUrl == null), isTrue);
  });
}
