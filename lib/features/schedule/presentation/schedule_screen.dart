import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder until M6.
class ScheduleScreen extends StatelessWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: AppIcons.schedule,
    message: AppLocalizations.of(context).schedulePlaceholder,
  );
}
