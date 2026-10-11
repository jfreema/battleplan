import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Shown when this build is older than Remote Config's
/// `min_supported_version` (ARCH §9). Store links arrive with the listings.
class UpdateRequiredScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.updateRequiredTitle)),
      body: EmptyState(icon: AppIcons.update, message: l10n.updateRequiredBody),
    );
  }
}
