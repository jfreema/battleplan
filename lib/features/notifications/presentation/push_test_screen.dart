import 'dart:async';

import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Dev-only screen for M0 spike 3: asks for permission, shows this device's
/// push token so a test message can be sent to it, and shows messages that
/// arrive while the app is open. Not translated, because it never ships.
class PushTestScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PushTestScreen> createState() => _PushTestScreenState();
}

class _PushTestScreenState extends ConsumerState<PushTestScreen> {
  String? _token;
  bool _asked = false;
  final _received = <PushMessage>[];
  StreamSubscription<PushMessage>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref
        .read(pushRepositoryProvider)
        .foregroundMessages()
        .listen((m) => setState(() => _received.insert(0, m)));
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  Future<void> _register() async {
    final push = ref.read(pushRepositoryProvider);
    await push.requestPermission();
    final token = await push.currentToken();
    if (!mounted) return;
    setState(() {
      _asked = true;
      _token = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    final token = _token;
    return Scaffold(
      appBar: AppBar(title: const Text('Push test (dev only)')),
      body: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          FilledButton(
            key: const Key('registerPush'),
            onPressed: _register,
            child: const Text('Allow notifications and get token'),
          ),
          const SizedBox(height: Space.lg),
          if (_asked && token == null)
            const Text(
              'No token: permission was declined or push is not available here.',
            ),
          if (token != null) ...[
            const Text("This device's token:"),
            const SizedBox(height: Space.sm),
            SelectableText(token, key: const Key('pushToken')),
            TextButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: token)),
              child: const Text('Copy token'),
            ),
          ],
          const SizedBox(height: Space.xl),
          const Text('Received while open:'),
          for (final m in _received)
            ListTile(title: Text(m.title ?? ''), subtitle: Text(m.body ?? '')),
        ],
      ),
    );
  }
}
