import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/features/safety/application/providers.dart';
import 'package:battleplan/features/safety/presentation/safety_actions.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Settings → Blocked people (SET-5): everyone you blocked, with Unblock.
class BlockedPeopleScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final blocked = ref.watch(blockedPeopleProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockedPeople)),
      body: blocked.isEmpty
          ? EmptyState(icon: AppIcons.check, message: l10n.noBlockedPeople)
          : ListView(
              children: [
                for (final b in blocked)
                  ListTile(
                    leading: Avatar(name: b.name, colorKey: b.uid.value),
                    title: Text(b.name.isEmpty ? l10n.formerMember : b.name),
                    trailing: TextButton(
                      onPressed: () => unawaited(unblock(context, ref, b.uid)),
                      child: Text(l10n.unblock),
                    ),
                  ),
              ],
            ),
    );
  }
}
