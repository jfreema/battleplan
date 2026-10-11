// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Battleplan';

  @override
  String get tagline => 'Chat, schedule, and RSVPs for your team';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabSchedule => 'Schedule';

  @override
  String get tabDocuments => 'Documents';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithFacebook => 'Continue with Facebook';

  @override
  String get continueWithEmail => 'Continue with email';

  @override
  String get signInTermsFooter =>
      'By continuing you agree to the Terms and Privacy Policy';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInFailed =>
      'That email and password don\'t match. Check them and try again.';

  @override
  String get signInOffline =>
      'You\'re offline. Check your connection and try again.';

  @override
  String get signInRateLimited => 'Slow down, try again in a minute.';

  @override
  String get signInDisabled =>
      'This account has been disabled. Contact support.';

  @override
  String get signInUnknownError => 'Something went wrong. Try again.';

  @override
  String get emulatorHint =>
      'Emulator accounts use the password \"password\", e.g. coach@example.com.';

  @override
  String get welcomeTitle => 'Welcome to Battleplan';

  @override
  String get welcomeBody =>
      'Join your team with an invite link or code, or create a new team.';

  @override
  String get joinTeam => 'Join a team';

  @override
  String get createTeam => 'Create a team';

  @override
  String get teamSwitcherTitle => 'Your teams';

  @override
  String get archivedTeams => 'Archived';

  @override
  String get switchTeamTooltip => 'Switch team';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get teamMenuTooltip => 'Team menu';

  @override
  String get accountMenuTooltip => 'Account';

  @override
  String get rosterMenu => 'Roster';

  @override
  String get inviteMenu => 'Invite';

  @override
  String get teamNotificationsMenu => 'Notifications for this team';

  @override
  String get teamSettingsMenu => 'Team settings';

  @override
  String get leaveTeamMenu => 'Leave team';

  @override
  String get settings => 'Settings';

  @override
  String get adminPanel => 'Admin panel';

  @override
  String get signOut => 'Sign out';

  @override
  String get chatPlaceholder => 'Messages for this team will appear here.';

  @override
  String get schedulePlaceholder =>
      'Practices, games, and RSVPs will appear here.';

  @override
  String get documentsPlaceholder =>
      'Share schedules, forms, and playbooks with your team.';

  @override
  String get notificationsPlaceholder =>
      'Activity from all your teams will appear here.';

  @override
  String get adminPlaceholder =>
      'The admin panel arrives in a later milestone.';

  @override
  String get notAMember => 'You\'re not a member of this team.';

  @override
  String get goToMyTeams => 'Go to my teams';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get about => 'About';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get updateRequiredTitle => 'Update Battleplan';

  @override
  String get updateRequiredBody =>
      'This version is no longer supported. Update to keep using Battleplan.';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread messages',
      one: '1 unread message',
    );
    return '$_temp0';
  }

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get loadError =>
      'Couldn\'t load this. Check your connection and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';
}
