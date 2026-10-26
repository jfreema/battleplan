import 'package:battleplan/core/constants.g.dart';

/// The team color [argb] as the app shows it (TEAM-5). A color taken out of
/// the palette (Royal blue, Violet) reads as the one that replaced it (Blue,
/// Purple), so its swatch shows as picked and the team takes that color's
/// tint and badge. The team's stored value doesn't change.
int? currentTeamColor(int? argb) => retiredTeamColorValues[argb] ?? argb;
