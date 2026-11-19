import 'package:battleplan/app/route_extra_codec.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/groups/presentation/invite_screen.dart';
import 'package:battleplan/features/groups/presentation/join_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

/// #33: the app's route extras survive go_router's refreshes, which re-run
/// the redirects whenever sign-in, my teams, or my profile change: a back
/// label such as "‹ Teams", and Invite's "Hornets is ready!" (ARCH §5.4).
void main() {
  const codec = RouteExtraCodec();

  test('each extra the app passes comes back as it was', () {
    Object? again(Object? extra) => codec.decode(codec.encode(extra));
    expect((again(const BackLabel('Teams'))! as BackLabel).label, 'Teams');
    expect(again(const BackLabel(null)), isA<BackLabel>());
    expect((again(const BackLabel(null))! as BackLabel).label, isNull);
    final code = again(const FromCodeBox('Join a Team or Group'));
    expect(code, isA<FromCodeBox>());
    expect((code! as FromCodeBox).label, 'Join a Team or Group');
    expect(again(const InviteAfterCreate()), isA<InviteAfterCreate>());
    // Anything else is dropped, as before.
    expect(again(null), isNull);
    expect(again(DateTime(2030)), isNull);
    expect(codec.decode({'type': 'somethingNew'}), isNull);
  });

  testWidgets('a page opened from Teams keeps "‹ Teams" through a refresh', (
    tester,
  ) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(
        user: const AuthUser(
          uid: 'coach',
          email: 'coach@example.com',
          emailVerified: true,
        ),
      ),
      groupRepo: FakeGroupRepository({}),
    );
    await tester.tap(find.text('Create a Team'));
    await tester.pumpAndSettle();
    expect(find.text('Teams'), findsOneWidget);
    GoRouter.of(tester.element(find.byType(Scaffold).last)).refresh();
    await tester.pumpAndSettle();
    expect(find.text('Teams'), findsOneWidget);
  });
}
