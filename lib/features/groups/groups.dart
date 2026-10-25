/// The groups feature's public widgets (ARCH §5.2 rule 7). Other features
/// import this file, never groups' presentation/ files.
library;

export 'presentation/chat_bubble_colors.dart' show chatBubbleColor;
export 'presentation/create_team_screen.dart' show sportName;
export 'presentation/gumdrop_rows.dart'
    show
        CardHeading,
        GumdropBackButton,
        LabeledField,
        PageHeading,
        RowDisc,
        SettingsCard,
        SettingsPanel,
        SettingsRow,
        gumdropAppBar,
        gumdropField,
        gumdropFieldText,
        switchRowTitle;
export 'presentation/results_screen.dart'
    show AddResultsScreen, ResultSection, describeAddProblem;
export 'presentation/roster_screen.dart' show roleBadge;
export 'presentation/storage_widgets.dart'
    show StorageMeter, changeStorageQuota, formatBytes, showStorageFull;
