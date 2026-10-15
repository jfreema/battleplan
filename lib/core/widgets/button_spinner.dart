import 'package:material_ui/material_ui.dart';

/// A button's spinner while it works.
class ButtonSpinner extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
