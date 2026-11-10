import 'package:flutter/widgets.dart';

/// The sheets, dialogs, and menus open in the app: every route without a
/// page, in the app's navigator and in a team's tabs' navigators, whose
/// changes go_router passes on to the app's observers.
///
/// A change of team closes them all, wherever they are in a stack, so
/// nothing opened on one team is left to act on another (`TeamShell`, SPEC
/// §5.2). Closing only what's on top isn't enough: a notification can open
/// another team's page over the tabs (an event, a player card), and a
/// person's card left under it would come back on Back.
class OpenSheets extends NavigatorObserver {
  final List<Route<dynamic>> _open = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Forgets any whose navigator has gone, as a tab's does when the team's
    // screen gives way to "not a member".
    _open.removeWhere((r) => r.navigator == null);
    if (route.settings is! Page) _open.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _open.remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _open.remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _open.remove(oldRoute);
    if (newRoute != null && newRoute.settings is! Page) _open.add(newRoute);
  }

  /// Closes every one, newest first: one showing slides away as usual, and
  /// one covered by a page or left in a hidden tab goes at once, unseen.
  /// Each one's future completes with null, as when it's dismissed.
  void closeAll() {
    for (final route in _open.reversed.toList()) {
      final navigator = route.navigator;
      if (navigator == null || !route.isActive) {
        _open.remove(route);
      } else if (route.isCurrent && _animates(navigator)) {
        navigator.pop();
      } else {
        navigator.removeRoute(route);
      }
    }
  }

  /// Whether a route in [navigator] can play its closing animation. A
  /// hidden tab's navigator can't: its tickers are off (go_router's
  /// `TickerMode` around each hidden branch), so a popped sheet would wait
  /// there half-closed and slide away over the next team when the tab
  /// shows again.
  static bool _animates(NavigatorState navigator) =>
      TickerMode.getValuesNotifier(navigator.context).value.enabled;
}
