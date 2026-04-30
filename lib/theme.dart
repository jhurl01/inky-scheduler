import 'package:flutter/material.dart';

// ── Palette ──────────────────────────────────────────────────────────────────

const kBackground = Color(0xFFF9F7F3); // warm off-white — scaffold + nav bar
const kNearBlack = Color(0xFF2C2A27); // text, icons, FAB
const kMutedGray = Color(0xFFB0ABA5); // secondary labels, inactive icons
const kCardSurface = Color(0xFFFFFFFF); // sheets & elevated surfaces
const kBorder = Color(0xFFE8E4DF); // subtle dividers

// Default accent used before the user picks a color
const kDefaultAccent = Color(0xFFB8A9D9);

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Parse a #RRGGBB hex string into a Color.
Color hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

/// Convert a Color to a #RRGGBB hex string (no alpha).
String colorToHex(Color color) {
  return '#${color.red.toRadixString(16).padLeft(2, '0')}'
      '${color.green.toRadixString(16).padLeft(2, '0')}'
      '${color.blue.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}

// ── Theme ─────────────────────────────────────────────────────────────────────

ThemeData buildInkyTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kBackground,
    colorScheme: const ColorScheme.light(
      primary: kNearBlack,
      secondary: kNearBlack,
      surface: kBackground,
      onSurface: kNearBlack,
      outline: kBorder,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      foregroundColor: kNearBlack,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: kNearBlack,
        fontSize: 17,
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: kBackground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: kCardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kCardSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kNearBlack, width: 1.5),
      ),
      hintStyle: const TextStyle(color: kMutedGray, fontSize: 15),
      counterStyle: const TextStyle(color: kMutedGray, fontSize: 12),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: kNearBlack, fontSize: 15),
      bodySmall: TextStyle(color: kMutedGray, fontSize: 13),
      labelSmall: TextStyle(color: kMutedGray, fontSize: 11),
    ),
    dividerTheme: const DividerThemeData(color: kBorder, space: 1),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kNearBlack,
      foregroundColor: kBackground,
      elevation: 2,
    ),
  );
}
