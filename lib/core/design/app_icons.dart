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
  static const IconData pdf = Symbols.picture_as_pdf_rounded;
  static const IconData image = Symbols.image_rounded;
  static const IconData spreadsheet = Symbols.table_chart_rounded;
  static const IconData slides = Symbols.slideshow_rounded;
  static const IconData link = Symbols.link_rounded;
  static const IconData upload = Symbols.upload_file_rounded;
  static const IconData pin = Symbols.push_pin_rounded;
  static const IconData openExternal = Symbols.open_in_new_rounded;
  static const IconData search = Symbols.search_rounded;
  static const IconData sort = Symbols.sort_rounded;
  static const IconData info = Symbols.info_rounded;
  static const IconData warning = Symbols.warning_rounded;
  static const IconData dashboard = Symbols.dashboard_rounded;
  static const IconData person = Symbols.person_rounded;
  static const IconData history = Symbols.history_rounded;
  static const IconData tune = Symbols.tune_rounded;
  static const IconData back = Symbols.arrow_back_rounded;
  static const IconData suspend = Symbols.pause_circle_rounded;
  static const IconData archive = Symbols.archive_rounded;
  static const IconData unarchive = Symbols.unarchive_rounded;
  static const IconData key = Symbols.key_rounded;
  static const IconData homeScreen = Symbols.add_to_home_screen_rounded;
  static const IconData location = Symbols.location_on_rounded;
  static const IconData directions = Symbols.directions_rounded;
  static const IconData addToCalendar = Symbols.calendar_add_on_rounded;
  static const IconData repeat = Symbols.repeat_rounded;
  static const IconData time = Symbols.schedule_rounded;
  static const IconData timeZone = Symbols.public_rounded;
  static const IconData notes = Symbols.notes_rounded;
  static const IconData duplicate = Symbols.content_copy_rounded;
  static const IconData cancelEvent = Symbols.event_busy_rounded;
  static const IconData rsvp = Symbols.how_to_reg_rounded;
  static const IconData filter = Symbols.filter_list_rounded;
  static const IconData chevronLeft = Symbols.chevron_left_rounded;
  static const IconData chevronRight = Symbols.chevron_right_rounded;

  /// Mentions and announcements (CHAT-14, CHAT-15).
  static const IconData mention = Symbols.alternate_email_rounded;
  static const IconData announcement = Symbols.campaign_rounded;
  static const IconData unpin = Symbols.keep_off_rounded;

  /// Contact sharing (TEAM-10).
  static const IconData sms = Symbols.sms_rounded;
  static const IconData contactInfo = Symbols.contact_phone_rounded;

  /// Player details (PLAYER-12).
  static const IconData birthday = Symbols.cake_rounded;
  static const IconData call = Symbols.call_rounded;
  static const IconData medical = Symbols.medical_information_rounded;

  /// Event types (SCHED-1), next to their colors.
  static const IconData game = Symbols.sports_score_rounded;
  static const IconData practice = Symbols.directions_run_rounded;
  static const IconData meeting = Symbols.groups_rounded;
  static const IconData social = Symbols.celebration_rounded;

  /// RSVP answers (SCHED-4).
  static const IconData going = Symbols.check_circle_rounded;
  static const IconData maybe = Symbols.help_rounded;
  static const IconData notGoing = Symbols.cancel_rounded;

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
  static const IconData cloudOff = Symbols.cloud_off_rounded;

  // Plays (BOARD-1 to BOARD-5): the board's tools. The Plays icon itself is
  // drawn (core/widgets/plays_icon.dart): no font has X's and O's on a
  // chalkboard.
  static const IconData toolMove = Symbols.pan_tool_rounded;
  static const IconData toolTeam = Symbols.person_rounded;
  static const IconData toolOpponent = Symbols.close_rounded;
  static const IconData toolBall = Symbols.sports_baseball_rounded;
  static const IconData toolRun = Symbols.north_east_rounded;
  static const IconData toolPass = Symbols.timeline_rounded;
  static const IconData toolBlock = Symbols.vertical_align_top_rounded;
  static const IconData toolDraw = Symbols.gesture_rounded;
  static const IconData toolText = Symbols.text_fields_rounded;
  static const IconData toolErase = Symbols.ink_eraser_rounded;
  static const IconData undo = Symbols.undo_rounded;
  static const IconData redo = Symbols.redo_rounded;
  static const IconData stepBack = Symbols.skip_previous_rounded;
  static const IconData stepNext = Symbols.skip_next_rounded;
  static const IconData play = Symbols.play_arrow_rounded;
  static const IconData stop = Symbols.stop_rounded;
  static const IconData savedPlays = Symbols.folder_open_rounded;
  static const IconData save = Symbols.save_rounded;
}
