// Widgets ask BrowserInfo whether they run in a browser instead of checking
// kIsWeb themselves (ARCH §5.2 rule 8, SPEC ENG-2).
import 'package:battleplan/core/services/browser_info.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/photo_viewer.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';

Future<void> _pumpViewer(WidgetTester tester, {required bool web}) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [
          browserInfoProvider.overrideWithValue(FakeBrowserInfo(isWeb: web)),
          messageRepositoryProvider.overrideWithValue(FakeMessageRepository()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoViewer(
            photos: [Attachment(path: 'groups/a/messages/m1/0.jpg')],
          ),
        ),
      ),
    );

void main() {
  test('phones and tests are not a browser', () {
    expect(const PlainBrowserInfo().isWeb, isFalse);
    expect(const PlainBrowserInfo().pushNeedsHomeScreen, isFalse);
  });

  testWidgets('the photo viewer offers Download in a browser (CHAT-3)', (
    tester,
  ) async {
    await _pumpViewer(tester, web: true);
    expect(find.byTooltip('Download'), findsOneWidget);
    expect(find.byTooltip('Share'), findsOneWidget);
  });

  testWidgets('and only Share on phones, which offers Save', (tester) async {
    await _pumpViewer(tester, web: false);
    expect(find.byTooltip('Download'), findsNothing);
    expect(find.byTooltip('Share'), findsOneWidget);
  });
}
