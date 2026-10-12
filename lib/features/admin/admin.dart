/// The admin feature's public widgets (ARCH §5.2 rule 7). Other features
/// and the app import this file, never admin's presentation/ files. The
/// panel itself (`presentation/admin_panel.dart`) is loaded separately, so
/// only what everyone needs is here.
library;

export 'presentation/announcement_banner.dart' show AnnouncementBanner;
export 'presentation/upload_limit.dart' show fitsUploadLimit;
export 'presentation/view_team_banner.dart' show ViewingAsSuperAdminBanner;
