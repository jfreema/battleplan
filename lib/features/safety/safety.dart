/// The safety feature's public widgets and actions (ARCH §5.2 rule 7).
/// Other features import this file, never safety's presentation/ files.
library;

export 'domain/safety.dart' show ReportTargetType;
export 'presentation/safety_actions.dart'
    show confirmBlock, reportReasonLabel, showReportSheet, unblock;
