import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Pulls an invite code out of typed text or a scanned link: accepts
/// `K7XP-M2QR`, `k7xpm2qr`, or `https://…/join/K7XPM2QR`.
String? inviteCodeFrom(String input) {
  final text = input.trim();
  final fromUrl = RegExp('/join/([0-9A-Za-z-]+)').firstMatch(text)?.group(1);
  final raw = (fromUrl ?? text).toUpperCase().replaceAll(
    RegExp('[^0-9A-Z]'),
    '',
  );
  return raw.length == 8 ? raw : null;
}

/// Join without a link (INV-6), at `/join`: type the code, or scan the
/// team's QR code with the camera (phones and browsers).
class EnterCodeScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _go(String input) {
    final code = inviteCodeFrom(input);
    if (code == null) {
      setState(() => _error = AppLocalizations.of(context).inviteCodeInvalid);
      return;
    }
    context.go('/join/$code');
  }

  Future<void> _scan() async {
    final scanned = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const _ScanScreen()));
    if (scanned != null && mounted) _go(scanned);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinTeam)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _code,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.inviteCodeLabel,
                    hintText: 'K7XP-M2QR',
                    errorText: error,
                  ),
                  onSubmitted: _go,
                ),
                const SizedBox(height: Space.lg),
                FilledButton(
                  onPressed: () => _go(_code.text),
                  child: Text(l10n.joinTeamButton),
                ),
                const SizedBox(height: Space.xl),
                OutlinedButton.icon(
                  onPressed: _scan,
                  icon: const Icon(AppIcons.qr),
                  label: Text(l10n.scanQrCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The camera view for scanning a team's QR code. Returns the scanned text.
class _ScanScreen extends StatefulWidget {
  const new();

  @override
  State<_ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<_ScanScreen> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanQrCode)),
      body: MobileScanner(
        onDetect: (capture) {
          final value = capture.barcodes
              .map((b) => b.rawValue)
              .whereType<String>()
              .firstOrNull;
          if (value == null || _done || inviteCodeFrom(value) == null) return;
          _done = true;
          Navigator.of(context).pop(value);
        },
        errorBuilder: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Text(l10n.cameraUnavailable, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
