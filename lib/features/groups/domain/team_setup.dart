/// A new team's setup card (TEAM-1, #3; owner's go 2026-11-16): what's done
/// of its steps. Each ticks itself off from what the team has, with no
/// button to press, so an import that brings players or events ticks those
/// too.
typedef TeamSetup = ({
  /// A basic group (TEAM-14): no players step, and group words.
  bool group,

  /// The team has a player (`playerCount > 0`).
  bool players,

  /// Someone else has joined (`memberCount > 1`).
  bool invited,

  /// The team has an event, upcoming or past.
  bool event,
});

/// The setup card's steps, in the order to do them: players before
/// inviting, so parents have someone to pick when they join (#11).
enum SetupStep { players, invite, event }

/// What the card shows of a [TeamSetup].
extension TeamSetupSteps on TeamSetup {
  /// The steps on the card: a group has no players step (TEAM-14).
  List<SetupStep> get steps => [
    if (!group) SetupStep.players,
    SetupStep.invite,
    SetupStep.event,
  ];

  /// Whether [step] is ticked off.
  bool isDone(SetupStep step) => switch (step) {
    SetupStep.players => players,
    SetupStep.invite => invited,
    SetupStep.event => event,
  };

  /// The one thing to do next, the first step not yet done, which alone is
  /// coral; null once they all are.
  SetupStep? get next => steps.where((s) => !isDone(s)).firstOrNull;

  /// Every step is done: "Hornets is ready", with Done.
  bool get ready => next == null;
}
