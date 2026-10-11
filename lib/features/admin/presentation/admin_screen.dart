import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder for the God admin panel (M8). Deferred-loaded on web.
class AdminScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminPanel)),
      body: EmptyState(icon: AppIcons.admin, message: l10n.adminPlaceholder),
    );
  }
}
