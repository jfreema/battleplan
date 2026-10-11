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
}
