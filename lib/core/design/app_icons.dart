import 'package:battleplan/core/constants.g.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Every icon the app uses, from Material Symbols Rounded (SPEC §7.3), so the
/// set stays the same on every platform.
abstract final class AppIcons {
  static const IconData chat = Symbols.chat_bubble_rounded;
  static const IconData schedule = Symbols.calendar_month_rounded;
  static const IconData documents = Symbols.folder_rounded;
  static const IconData notifications = Symbols.notifications_rounded;
  static const IconData more = Symbols.more_horiz_rounded;
  static const IconData expand = Symbols.expand_more_rounded;
  static const IconData settings = Symbols.settings_rounded;
  static const IconData signOut = Symbols.logout_rounded;
  static const IconData add = Symbols.add_rounded;
  static const IconData group = Symbols.groups_rounded;
  static const IconData roster = Symbols.group_rounded;
  static const IconData invite = Symbols.person_add_rounded;
  static const IconData leave = Symbols.exit_to_app_rounded;
  static const IconData admin = Symbols.shield_person_rounded;
  static const IconData lightMode = Symbols.light_mode_rounded;
  static const IconData darkMode = Symbols.dark_mode_rounded;
  static const IconData systemMode = Symbols.brightness_auto_rounded;
  static const IconData email = Symbols.mail_rounded;
  static const IconData visibility = Symbols.visibility_rounded;
  static const IconData visibilityOff = Symbols.visibility_off_rounded;
  static const IconData update = Symbols.system_update_rounded;
  static const IconData error = Symbols.error_rounded;
  static const IconData muted = Symbols.notifications_off_rounded;
  static const IconData qr = Symbols.qr_code_scanner_rounded;
  static const IconData check = Symbols.check_rounded;
  static const IconData edit = Symbols.edit_rounded;
  static const IconData close = Symbols.close_rounded;
  static const IconData send = Symbols.send_rounded;
  static const IconData share = Symbols.share_rounded;
  static const IconData download = Symbols.download_rounded;
  static const IconData photo = Symbols.photo_library_rounded;
  static const IconData camera = Symbols.photo_camera_rounded;
  static const IconData retry = Symbols.refresh_rounded;
  static const IconData addReaction = Symbols.add_reaction_rounded;
  static const IconData copy = Symbols.content_copy_rounded;
  static const IconData reply = Symbols.reply_rounded;
  static const IconData delete = Symbols.delete_rounded;
  static const IconData arrowDown = Symbols.arrow_downward_rounded;
  static const IconData report = Symbols.flag_rounded;
  static const IconData block = Symbols.block_rounded;
  static const IconData notificationsOn = Symbols.notifications_active_rounded;
  static const IconData markAllRead = Symbols.done_all_rounded;
  static const IconData addedToTeam = Symbols.group_add_rounded;
  static const IconData family = Symbols.family_restroom_rounded;
  static const IconData storage = Symbols.storage_rounded;
  static const IconData media = Symbols.perm_media_rounded;
  static const IconData file = Symbols.insert_drive_file_rounded;
  static const IconData poll = Symbols.poll_rounded;
  static const IconData event = Symbols.event_rounded;
  static const IconData reminder = Symbols.alarm_rounded;
  static const IconData document = Symbols.description_rounded;
  static const IconData homeScreen = Symbols.add_to_home_screen_rounded;

  /// The icon for a sport (shown in the team switcher).
  static IconData sport(Sport sport) => switch (sport) {
    Sport.baseball || Sport.softball => Symbols.sports_baseball_rounded,
    Sport.basketball => Symbols.sports_basketball_rounded,
    Sport.football => Symbols.sports_football_rounded,
    Sport.hockey => Symbols.sports_hockey_rounded,
    Sport.lacrosse => Symbols.sports_rounded,
    Sport.soccer => Symbols.sports_soccer_rounded,
    Sport.volleyball => Symbols.sports_volleyball_rounded,
    Sport.other => Symbols.sports_rounded,
  };
}
