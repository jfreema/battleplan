import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder for the notification center (NOTIF-11, M4).
class NotificationsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTooltip)),
      body: EmptyState(
        icon: AppIcons.notifications,
        message: l10n.notificationsPlaceholder,
      ),
    );
  }
}
