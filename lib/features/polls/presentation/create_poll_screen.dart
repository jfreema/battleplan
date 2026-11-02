import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/viewer_zone.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/features/polls/presentation/poll_card.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the new-poll screen (POLL-1) and returns the poll to post, or null
/// if it was closed without posting. It covers the whole app, tabs
/// included.
Future<NewPoll?> showCreatePoll(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push<NewPoll>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CreatePollScreen(),
      ),
    );

/// A question (up to 200 characters), 2 to 10 options (up to 80 each, in
/// any order), and the settings: multiple answers, anonymous voting, and a
/// close time.
class CreatePollScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _question = TextEditingController();

  /// Each option's field, keyed so reordering keeps what was typed.
  final List<({Key key, TextEditingController text})> _options = [
    for (var i = 0; i < Limits.pollOptionsMin; i++)
      (key: UniqueKey(), text: TextEditingController()),
  ];
  bool _multiple = false;
  bool _anonymous = false;
  DateTime? _closesAt;

  @override
  void dispose() {
    _question.dispose();
    for (final o in _options) {
      o.text.dispose();
    }
    super.dispose();
  }

  NewPoll get _poll => NewPoll(
    question: _question.text,
    options: [for (final o in _options) o.text.text],
    allowMultiple: _multiple,
    anonymous: _anonymous,
    closesAt: _closesAt,
  );

  bool get _touched =>
      _question.text.trim().isNotEmpty ||
      _options.any((o) => o.text.text.trim().isNotEmpty);

  void _addOption() => setState(
    () => _options.add((key: UniqueKey(), text: TextEditingController())),
  );

  void _removeOption(int i) =>
      setState(() => _options.removeAt(i).text.dispose());

  /// Picks the close date, then the time, in the viewer's zone (SET-7).
  /// Defaults to this time tomorrow, on the hour.
  Future<void> _pickCloseTime() async {
    final zone = ViewerZone.read(context);
    final now = wallClockIn(zone, DateTime.now());
    final initial = _closesAt == null
        ? DateTime(now.year, now.month, now.day + 1, now.hour + 1)
        : wallClockIn(zone, _closesAt!);
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: today,
      // The rules allow up to a year ahead.
      lastDate: DateTime(now.year, now.month, now.day + 365),
      currentDate: today,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    // The picked day and time are wall-clock time in the viewer's zone.
    setState(
      () => _closesAt = zone == null
          ? DateTime(date.year, date.month, date.day, time.hour, time.minute)
          : ZonedTime.instantOf(
              zone,
              DateTime.utc(date.year, date.month, date.day),
              time.hour * 60 + time.minute,
            ),
    );
  }

  Future<void> _leave() async {
    if (!_touched) {
      Navigator.of(context).pop();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final discard = await showConfirmDialog(
      context,
      title: l10n.pollDiscardTitle,
      confirmLabel: l10n.pollDiscard,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final valid = _poll.isValidAt(now);
    final closesPast = _closesAt != null && !_closesAt!.isAfter(now);
    return PopScope(
      canPop: !_touched,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.cancel,
            icon: const Icon(AppIcons.close),
            onPressed: () => unawaited(_leave()),
          ),
          title: Text(l10n.newPoll),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: Space.sm),
              child: FilledButton(
                onPressed: valid
                    ? () => Navigator.of(context).pop(_poll.tidy)
                    : null,
                child: Text(l10n.pollPost),
              ),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(Space.lg),
              children: [
                TextField(
                  controller: _question,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: Limits.pollQuestionMax,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.pollQuestion,
                    border: const OutlineInputBorder(),
                    // Some emoji count as more than one character.
                    errorText: tooLong(_question.text, Limits.pollQuestionMax)
                        ? l10n.pollTooLong
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Space.sm),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorderItem: (from, to) => setState(
                    () => _options.insert(to, _options.removeAt(from)),
                  ),
                  children: [
                    for (final (i, o) in _options.indexed)
                      Padding(
                        key: o.key,
                        padding: const EdgeInsets.only(bottom: Space.sm),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: i,
                              child: const Padding(
                                padding: EdgeInsets.all(Space.sm),
                                child: Icon(Icons.drag_indicator),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: o.text,
                                maxLength: Limits.pollOptionTextMax,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  hintText: l10n.pollOptionHint(i + 1),
                                  isDense: true,
                                  counterText: '',
                                  border: const OutlineInputBorder(),
                                  errorText:
                                      tooLong(
                                        o.text.text,
                                        Limits.pollOptionTextMax,
                                      )
                                      ? l10n.pollTooLong
                                      : null,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            if (_options.length > Limits.pollOptionsMin)
                              IconButton(
                                tooltip: l10n.pollRemoveOption,
                                icon: const Icon(AppIcons.close),
                                onPressed: () => _removeOption(i),
                              )
                            else
                              const SizedBox(width: 48),
                          ],
                        ),
                      ),
                  ],
                ),
                if (_options.length < Limits.pollOptionsMax)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: _addOption,
                      icon: const Icon(AppIcons.add),
                      label: Text(l10n.pollAddOption),
                    ),
                  ),
                const Divider(height: Space.xl),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.pollAllowMultiple),
                  value: _multiple,
                  onChanged: (v) => setState(() => _multiple = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.pollAnonymousVoting),
                  subtitle: Text(l10n.pollAnonymousHelp),
                  value: _anonymous,
                  onChanged: (v) => setState(() => _anonymous = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.pollCloseAutomatically),
                  value: _closesAt != null,
                  onChanged: (on) => on
                      ? unawaited(_pickCloseTime())
                      : setState(() => _closesAt = null),
                ),
                if (_closesAt case final at?)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(AppIcons.schedule),
                    title: Text(l10n.pollClosesOn),
                    subtitle: Text(
                      closesLabel(l10n, at, now, zone: ViewerZone.of(context)),
                      style: closesPast
                          ? TextStyle(color: theme.colorScheme.error)
                          : null,
                    ),
                    trailing: const Icon(AppIcons.edit),
                    onTap: () => unawaited(_pickCloseTime()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
