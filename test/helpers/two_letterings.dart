// A scheme with two letterings, for the tests. No scheme ships with them
// since Tropic Blue left (#106), but the theme editor can still give a scheme
// its own lettering on panels (#88), and the app has to draw it: text boxes
// and menus opened from the page take the camouflage's ground, and second
// lines, wells and Material's pop-ups follow.
import 'package:battleplan/core/camp_theme.dart';
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/theme_readability.dart';

/// The scheme the tests edit: Sky Blue, whose white panels under navy
/// lettering [twoLetterings] keeps.
const TeamScheme twoLetteringsScheme = TeamScheme.sky;

/// Tropic Blue's colors as it shipped (#90, style 50), as the theme editor's
/// changes to [twoLetteringsScheme]: an ocean-blue page under white
/// lettering, and white panels under deep-sea navy lettering.
const twoLetterings = CampTheme(
  colors: {
    CampColor.ink: 0xFF062033,
    CampColor.shadow: 0xFF062033,
    CampColor.page: 0xFF0A7EAC,
    CampColor.panel: 0xFFFFFFFF,
    CampColor.tabBar: 0xFF062A45,
    CampColor.text: 0xFFFFFFFF,
    CampColor.muted: 0xFFD8F1FF,
    CampColor.panelText: 0xFF062033,
    CampColor.panelMuted: 0xFF3D5F7A,
    CampColor.mustard: 0xFFFFD23F,
    CampColor.balloon: 0xFFFFD23F,
    CampColor.red: 0xFFFF5A4E,
    CampColor.blue: 0xFF4FCBF7,
    CampColor.green: 0xFF4FD38A,
    CampColor.orange: 0xFFFF9A2E,
    CampColor.purple: 0xFFB58BFF,
    CampColor.unansweredTag: 0xFFCDE7F2,
    CampColor.answerRow: 0xFFFFF1B0,
    CampColor.toolsRow: 0xFF0B76A3,
    CampColor.disabledIcon: 0xFF9CC3D6,
    CampColor.camoGround: 0xFF0A6E99,
    CampColor.camoBig: 0xFF075478,
    CampColor.camoMid: 0xFF1E9CC8,
    CampColor.camoSmall: 0xFF04324A,
    CampColor.headerLettering: 0xFFFFFFFF,
    CampColor.ballChain: 0xFFFFD23F,
  },
);

/// [twoLetteringsScheme]'s palette with [twoLetterings]' colors.
CampPalette get twoLetteringsPalette =>
    editedPalette(twoLetteringsScheme, twoLetterings.colors);
