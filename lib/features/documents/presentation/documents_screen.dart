import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder until M7. Uses the DOC-1 empty-state wording.
class DocumentsScreen extends StatelessWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: AppIcons.documents,
    message: AppLocalizations.of(context).documentsPlaceholder,
  );
}
