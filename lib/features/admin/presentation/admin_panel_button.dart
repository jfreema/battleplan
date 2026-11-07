import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/gumdrop_icon_button.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

// The ways into the God admin panel (SPEC §6.11 Access), one tap from
// where a super admin usually is. Only links to `/admin`: the panel's own
// code stays in its deferred library (ARCH §5.6), so nobody downloads it
// before opening it, and nobody else ever does.

/// Whether I'm a super admin, for the entries that only they see.
bool watchSuperAdmin(WidgetRef ref) =>
    ref.watch(authUserProvider.select((a) => a.value?.isSuperAdmin ?? false));

/// Opens the admin panel over the page that's showing, so Back comes back
/// to it.
void openAdminPanel(BuildContext context) => unawaited(context.push('/admin'));

/// The Admin panel button in the Teams header and a team's header, before
/// Messages (SPEC §5.1): the shield in a 48 px header icon button, for
/// super admins on phones. Nothing for anyone else, and nothing at 840 px
/// and up, where the rail's foot has it instead (§5.5).
class AdminPanelButton extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;
    if (!watchSuperAdmin(ref) || wide) return const SizedBox.shrink();
    return GumdropIconButton(
      tooltip: AppLocalizations.of(context).adminPanel,
      icon: AppIcons.admin,
      onPressed: () => openAdminPanel(context),
    );
  }
}
