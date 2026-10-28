/// Shared plays (SPEC BOARD-6): a play's public link is
/// `https://<host>/p/<shareId>`, which shows only the play.
library;

import 'package:battleplan/features/plays/domain/play.dart';

/// Whether [id] could be a shared play's ID: 12 URL-safe characters.
bool isShareId(String id) => RegExp(r'^[A-Za-z0-9_-]{12}$').hasMatch(id);

/// [play] as its public link may show it (BOARD-6): a marker labeled
/// with a roster player keeps its spot but loses the label, the player's
/// name. The server keeps the same in the shared copy; this is for the
/// picture the app draws for the link's preview.
Play publicPlay(Play play) => play.copyWith(
  steps: [
    for (final step in play.steps)
      PlayStep(
        elements: [
          for (final e in step.elements)
            if (e case MarkerElement(playerId: _?))
              e.copyWith(label: '', playerId: null)
            else
              e,
        ],
      ),
  ],
);
