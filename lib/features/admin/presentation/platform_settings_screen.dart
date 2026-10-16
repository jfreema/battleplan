import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/presentation/admin_widgets.dart';
import 'package:battleplan/features/admin/presentation/announcement_banner.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// ADMIN-7 at `/admin/settings`: whether anyone can create teams and how
/// many a day, the default storage quota and largest upload, the support
/// email, and the announcement banner (text, severity, end). Checked here
/// before saving, and again by the server.
class PlatformSettingsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PlatformSettingsScreen> createState() =>
      _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState
    extends ConsumerState<PlatformSettingsScreen> {
  final _perDay = TextEditingController();
  final _quota = TextEditingController();
  final _upload = TextEditingController();
  final _support = TextEditingController();
  final _bannerText = TextEditingController();
  bool _allowCreation = true;
  bool _emailAlerts = true;
  bool _bannerOn = false;
  BannerSeverity _severity = BannerSeverity.info;
  DateTime? _expiresAt;

  /// Filled from the saved settings once they arrive.
  bool _loaded = false;
  bool _saving = false;
  Set<ConfigProblem> _problems = const {};

  @override
  void dispose() {
    _perDay.dispose();
    _quota.dispose();
    _upload.dispose();
    _support.dispose();
    _bannerText.dispose();
    super.dispose();
  }

  void _load(AppConfig c) {
    _loaded = true;
    _allowCreation = c.allowUserGroupCreation;
    _emailAlerts = c.emailAdminAlerts;
    _perDay.text = '${c.maxGroupsCreatedPerUserPerDay}';
    _quota.text = '${c.defaultStorageQuotaMb}';
    _upload.text = '${c.maxUploadMb}';
    _support.text = c.supportEmail;
    final banner = c.announcementBanner;
    // An expired banner reads as none: it's no longer shown.
    _bannerOn = banner != null && banner.isLiveAt(DateTime.now());
    if (banner != null) {
      _bannerText.text = banner.text;
      _severity = banner.severity;
      _expiresAt = banner.expiresAt;
    }
  }

  AppConfig _read() => AppConfig(
    allowUserGroupCreation: _allowCreation,
    maxGroupsCreatedPerUserPerDay: int.tryParse(_perDay.text.trim()) ?? 0,
    defaultStorageQuotaMb: int.tryParse(_quota.text.trim()) ?? 0,
    maxUploadMb: int.tryParse(_upload.text.trim()) ?? 0,
    supportEmail: _support.text.trim(),
    emailAdminAlerts: _emailAlerts,
    announcementBanner: _bannerOn
        ? Announcement(
            text: _bannerText.text.trim(),
            severity: _severity,
            // No end chosen fails the check below.
            expiresAt: _expiresAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          )
        : null,
  );

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final config = _read();
    final problems = configProblems(config, DateTime.now());
    setState(() => _problems = problems);
    if (problems.isNotEmpty) return;
    setState(() => _saving = true);
    // The storage limit is every team's without its own (STORE-1), so a
    // save can move teams to it; say how many.
    var moved = 0;
    final saved = await runAdminAction(
      context,
      () async =>
          moved = await ref.read(adminRepositoryProvider).updateConfig(config),
    );
    if (saved && mounted) {
      showAppSnackBar(
        context,
        moved == 0
            ? l10n.adminSettingsSaved
            : l10n.adminSettingsSavedTeams(moved, config.defaultStorageQuotaMb),
      );
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final initial = _expiresAt ?? now.add(const Duration(days: 7));
    final day = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 366)),
      initialDate: initial.isBefore(now) ? now : initial,
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(
      () => _expiresAt = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);
    if (!_loaded && config.value != null) _load(config.value!);
    String? error(ConfigProblem p, String text) =>
        _problems.contains(p) ? text : null;

    Widget number(
      TextEditingController c,
      String label,
      String help,
      String? errorText,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          helperText: help,
          errorText: errorText,
        ),
      ),
    );

    return AdminScaffold(
      section: AdminSection.settings,
      title: l10n.adminSettings,
      body: !_loaded
          ? config.hasError
                ? Center(child: Text(l10n.loadError))
                : const Center(child: CircularProgressIndicator())
          : AdminBody(
              maxWidth: 640,
              children: [
                AdminSectionCard(
                  title: l10n.adminTeams,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.adminAllowCreation),
                      subtitle: Text(l10n.adminAllowCreationHelp),
                      value: _allowCreation,
                      onChanged: (v) => setState(() => _allowCreation = v),
                    ),
                    number(
                      _perDay,
                      l10n.adminTeamsPerDay,
                      l10n.adminRangeHelp(1, Limits.groupsPerUserMax),
                      error(
                        ConfigProblem.groupsPerDay,
                        l10n.adminRangeError(1, Limits.groupsPerUserMax),
                      ),
                    ),
                  ],
                ),
                AdminSectionCard(
                  title: l10n.storageSection,
                  children: [
                    number(
                      _quota,
                      l10n.adminDefaultQuota,
                      l10n.adminRangeHelp(1, Limits.storageQuotaMaxMb),
                      error(
                        ConfigProblem.defaultQuota,
                        l10n.adminRangeError(1, Limits.storageQuotaMaxMb),
                      ),
                    ),
                    number(
                      _upload,
                      l10n.adminMaxUpload,
                      l10n.adminRangeHelp(1, Limits.maxUploadMb),
                      error(
                        ConfigProblem.maxUpload,
                        l10n.adminRangeError(1, Limits.maxUploadMb),
                      ),
                    ),
                  ],
                ),
                // Emails to super admins about new accounts and teams
                // (ADMIN-9). Reports always email (SAFE-4).
                AdminSectionCard(
                  title: l10n.adminAlerts,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.adminEmailAlerts),
                      subtitle: Text(l10n.adminEmailAlertsHelp),
                      value: _emailAlerts,
                      onChanged: (v) => setState(() => _emailAlerts = v),
                    ),
                  ],
                ),
                AdminSectionCard(
                  title: l10n.contactSupport,
                  children: [
                    TextField(
                      controller: _support,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.adminSupportEmail,
                        errorText: error(
                          ConfigProblem.supportEmail,
                          l10n.emailInvalid,
                        ),
                      ),
                    ),
                  ],
                ),
                AdminSectionCard(
                  title: l10n.adminBanner,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.adminBannerOn),
                      subtitle: Text(l10n.adminBannerHelp),
                      value: _bannerOn,
                      onChanged: (v) => setState(() => _bannerOn = v),
                    ),
                    if (_bannerOn) ...[
                      TextField(
                        controller: _bannerText,
                        maxLength: announcementTextMax,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: l10n.adminBannerText,
                          errorText: error(
                            ConfigProblem.bannerText,
                            l10n.adminBannerTextError(announcementTextMax),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: Space.sm),
                      Text(
                        l10n.adminBannerSeverity,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: Space.xs),
                      SegmentedButton<BannerSeverity>(
                        segments: [
                          for (final s in BannerSeverity.values)
                            ButtonSegment(
                              value: s,
                              label: Text(severityLabel(l10n, s)),
                            ),
                        ],
                        selected: {_severity},
                        onSelectionChanged: (s) =>
                            setState(() => _severity = s.first),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(AppIcons.time),
                        title: Text(l10n.adminBannerEnds),
                        subtitle: Text(
                          _expiresAt == null
                              ? l10n.adminBannerNoEnd
                              : adminDateTime(l10n, _expiresAt),
                          style: _problems.contains(ConfigProblem.bannerExpiry)
                              ? TextStyle(color: theme.colorScheme.error)
                              : null,
                        ),
                        trailing: TextButton(
                          onPressed: () => unawaited(_pickEnd()),
                          child: Text(l10n.adminBannerPickEnd),
                        ),
                      ),
                      if (_problems.contains(ConfigProblem.bannerExpiry))
                        Text(
                          l10n.adminBannerEndError,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                    ],
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _saving ? null : () => unawaited(_save()),
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
    );
  }
}
