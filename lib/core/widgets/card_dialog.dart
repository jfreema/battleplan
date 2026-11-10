import 'package:battleplan/core/design/team_theme.dart';
import 'package:material_ui/material_ui.dart';

/// [showDialog] with its content in the card context (SPEC §7.4): a dialog
/// is drawn on a card, so its text, outlines and candy texts take the
/// card's colors, not the page's.
Future<T?> showCardDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  builder: (_) => GumdropSurface(child: Builder(builder: builder)),
);

/// [showModalBottomSheet] with its content in the card context, as
/// [showCardDialog]. It opens in the nearest navigator, a tab's own under
/// a team's header, or with [useRootNavigator] over the whole app.
Future<T?> showCardSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool? showDragHandle,
  bool useRootNavigator = false,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  useSafeArea: useSafeArea,
  showDragHandle: showDragHandle,
  useRootNavigator: useRootNavigator,
  builder: (_) => GumdropSurface(child: Builder(builder: builder)),
);
