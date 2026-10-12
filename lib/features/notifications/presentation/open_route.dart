import 'dart:async';

import 'package:battleplan/features/notifications/domain/notification_item.dart';
import 'package:go_router/go_router.dart';

/// Opens a notification's route, switching teams if needed (NOTIF-6).
/// Team tabs replace the stack, as the team switcher does; other screens
/// (roster, reports, the center) are pushed so Back returns. [replace]
/// always replaces: on a cold start nothing is underneath yet, and signed
/// out, the router sends the route through sign-in.
///
/// Returns false, doing nothing, for a route outside the allowlist.
bool openNotificationRoute(
  GoRouter router,
  String? route, {
  bool replace = false,
}) {
  if (route == null || !isAllowedNotificationRoute(route)) return false;
  if (replace || isTeamTabRoute(route)) {
    router.go(route);
  } else {
    unawaited(router.push<void>(route));
  }
  return true;
}
