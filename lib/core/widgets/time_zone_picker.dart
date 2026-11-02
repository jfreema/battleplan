import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/services/time_zone_names.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// A searchable list of time zones by the names people know them by
/// (SCHED-9), for a team's zone (TEAM-5) or the person's own (SET-7).
/// Pops the picked IANA ID. With [automatic], the first row is Automatic,
/// which pops [automaticChoice].
class TimeZonePicker extends StatefulWidget {
  const new({
    required this.zones,
    required this.current,
    this.automatic,
    this.help,
    super.key,
  });

  final List<String> zones;

  /// The zone that shows as chosen; null with [automatic] chooses that row.
  final String? current;

  /// The Automatic row's label, "Automatic: Central Time (Chicago)", or
  /// null for no such row.
  final String? automatic;

  /// A line under the title saying what the choice does.
  final String? help;

  /// What the Automatic row pops: a value no zone ID can be.
  static const automaticChoice = '';

  @override
  State<TimeZonePicker> createState() => _TimeZonePickerState();
}

class _TimeZonePickerState extends State<TimeZonePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = [
      for (final z in widget.zones)
        if (TimeZoneNames.matches(z, _query)) z,
    ];
    final automatic = widget.automatic;
    return AlertDialog(
      title: Text(l10n.timeZoneLabel),
      content: SizedBox(
        width: 400,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.help case final help?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(help, style: Theme.of(context).textTheme.bodySmall),
              ),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(AppIcons.search),
                hintText: l10n.timeZoneSearch,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: shown.length + (automatic == null ? 0 : 1),
                itemBuilder: (context, i) {
                  if (automatic != null && i == 0) {
                    return ListTile(
                      title: Text(automatic),
                      selected: widget.current == null,
                      onTap: () =>
                          Navigator.of(context)
                              .pop(TimeZonePicker.automaticChoice),
                    );
                  }
                  final z = shown[i - (automatic == null ? 0 : 1)];
                  return ListTile(
                    title: Text(TimeZoneNames.label(z)),
                    selected: z == widget.current,
                    onTap: () => Navigator.of(context).pop(z),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
