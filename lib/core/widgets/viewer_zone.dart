import 'package:battleplan/core/services/time_zones.dart';
import 'package:material_ui/material_ui.dart';

/// The viewer's time zone for everything below it (SET-7): the one they
/// picked under Profile → Time zone, or this device's. The app puts it
/// above every screen, so a widget showing a time asks [wallClock] and
/// redraws when the zone changes. Null (in a bare test) falls back to the
/// device's zone.
class ViewerZone extends InheritedWidget {
  const new({required this.zone, required super.child, super.key});

  final String? zone;

  /// The zone above [context], or null when there's none yet. In build;
  /// the widget redraws when it changes.
  static String? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ViewerZone>()?.zone;

  /// The zone above [context] once, for a callback such as a picker.
  static String? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ViewerZone>()?.zone;

  /// [instant] as wall-clock time in the viewer's zone, for formatting and
  /// for telling which day it was.
  static DateTime wallClock(BuildContext context, DateTime instant) =>
      wallClockIn(of(context), instant);

  @override
  bool updateShouldNotify(ViewerZone oldWidget) => zone != oldWidget.zone;
}
