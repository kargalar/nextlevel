import 'package:flutter/material.dart';

class AppColors {
  // Border Radius
  static const double borderRadius = 12;
  static BorderRadius borderRadiusAll =
      const BorderRadius.all(Radius.circular(borderRadius));
  static BorderRadius highBorderRadiusAll =
      const BorderRadius.all(Radius.circular(borderRadius * 3));
  static BorderRadius borderRadiusTop =
      const BorderRadius.vertical(top: Radius.circular(borderRadius));
  static BorderRadius borderRadiusBottom =
      const BorderRadius.vertical(bottom: Radius.circular(borderRadius));
  static BorderRadius borderRadiusCircular =
      const BorderRadius.all(Radius.circular(125));

  // Padding
  static const EdgeInsets showcasePadding = EdgeInsets.all(3);

  // Shadows
  static const List<Shadow> basicShadow = [
    Shadow(
      color: AppColors.transparantBlack,
      offset: Offset(1, 1),
      blurRadius: 2,
    ),
  ];
  static const List<BoxShadow> bottomShadow = [
    BoxShadow(
      spreadRadius: 0,
      blurRadius: 5,
      offset: Offset(0, 2),
    ),
  ];

  // Main Colors
  static const Color transparent = Color.fromRGBO(0, 0, 0, 0);
  static const Color deepBlack = Color(0xFF000000);
  static const Color deepWhite = Color.fromARGB(255, 255, 255, 255);
  static const Color black = Color(0xFF0C0C0C);
  static const Color lightblack = Color(0xFF1E1E1E);
  static const Color transparantBlack = Color.fromRGBO(16, 16, 16, 0.5);
  static const Color grey = Color(0xFF757575);
  static const Color dirtyWhite = Color(0xFFCCCCCC);
  static const Color white = Color.fromARGB(255, 250, 250, 250);
  static const Color red = Color(0xFFFF647C);
  static const Color dirtyRed = Color.fromARGB(255, 182, 28, 28);
  static const Color pink = Color.fromARGB(255, 224, 18, 163);
  static const Color blue = Color(0xFF6EA8FE);
  static const Color deepBlue = Color.fromARGB(255, 0, 83, 151);
  static const Color yellow = Color(0xFFFFD166);
  static const Color orange = Color(0xFFFFA552);
  static const Color orange2 = Color.fromARGB(255, 255, 152, 0);
  static const Color green = Color(0xFF4DD4AC);
  static const Color deepGreen = Color(0xFF35B88F);
  static const Color purple = Color(0xFFA78BFA);
  static const Color deepPurple = Color.fromARGB(255, 96, 3, 158);
  static const Color lightGreen = Color.fromARGB(255, 137, 224, 140);

  // Matte Colors
  static const Color matteRed = Color.fromARGB(255, 195, 85, 85);
  static const Color matteBlue = Color.fromARGB(255, 85, 145, 195);
  static const Color matteOrange = Color.fromARGB(255, 195, 135, 85);
  static const Color matteYellow = Color.fromARGB(255, 195, 185, 85);
  static const Color matteGrey = Color.fromARGB(255, 120, 120, 120);
  static const Color mattePurple = Color.fromARGB(255, 145, 85, 195);
  static const Color matteGreen = Color.fromARGB(255, 85, 195, 105);

  // General Colors
  static const Color cursor = Color.fromARGB(255, 204, 204, 204);

  // Button Colors
  static Color hover = const Color.fromARGB(48, 73, 73, 73);

  // Theme Colors
  static Color main = const Color(0xFF6C7CFF);
  static Color lightMain = const Color(0xFF9AA5FF);
  static Color deepMain = const Color(0xFF4654D6);
  static Color dirtyMain = const Color(0xFF5968E8);

  // Dynamic Colors
  static const Color background = Color(0xFF0C0C0C);
  static const Color onBackground = Color(0xFFF5F5F5);
  static const Color deepContrast = Color.fromARGB(255, 0, 0, 0);
  static const Color surface = Color(0xFF181818);
  static const Color surfaceRaised = Color(0xFF242424);
  static const Color surfaceHighest = Color(0xFF303030);
  static const Color outline = Color(0xFF404040);
  static const Color outlineSoft = Color(0xFF2B2B2B);
  static const Color text = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textMuted = Color(0xFF707070);
  static const Color panelBackground = surfaceRaised;
  static const Color panelBackgroundDark = surface;
  static const Color panelBackground2 = surfaceHighest;
  static const Color panelBackground3 = Color(0xFF383838);
  static const Color panelBackground4 = surfaceHighest;
  static const Color panelBackground5 = surfaceRaised;
  static const Color panelBackground6 = surface;
  static const Color appbar = surfaceRaised;

  // skillColors
  static List<Color> skillColors = [
    const Color.fromARGB(255, 255, 105, 0),
    const Color.fromARGB(255, 107, 65, 18),
    const Color.fromARGB(255, 110, 194, 0),
    const Color.fromARGB(255, 0, 195, 255),
    const Color.fromARGB(255, 255, 0, 221),
    const Color.fromARGB(255, 0, 3, 204),
    const Color.fromARGB(255, 228, 194, 0),
    const Color.fromARGB(255, 221, 7, 0),
    const Color.fromARGB(255, 89, 0, 255),
    const Color.fromARGB(255, 0, 88, 27),
    const Color.fromARGB(255, 129, 49, 29),
    const Color.fromARGB(255, 67, 0, 155),
  ];

  // ---------------------------------------------------------------------------------------------------------------
}
