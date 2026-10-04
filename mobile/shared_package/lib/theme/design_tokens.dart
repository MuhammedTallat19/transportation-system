import 'package:flutter/material.dart';

/// Transportation App design tokens — civic transit palette.
///
/// Primary deep blue (#0F4C81) conveys institutional trust and clarity,
/// common in government and transit branding. Secondary green (#2E8B57)
/// signals positive/on-time states. Teal accent (#00A8A8) highlights live
/// interactions without the flashiness of consumer-app neons.
class TransportationAppDesignTokens {
  TransportationAppDesignTokens._();

  static const Color primary = Color(0xFF0F4C81);
  static const Color primaryVariant = Color(0xFF0A355D);
  static const Color secondary = Color(0xFF2E8B57);
  static const Color accent = Color(0xFF00A8A8);
  static const Color transitTeal = Color(0xFF087E83);
  static const Color heroBlue = Color(0xFF0B456F);
  static const Color softMint = Color(0xFFE1F3EF);
  static const Color softBlue = Color(0xFFEAF2F5);
  static const Color warning = Color(0xFFB26A00);
  static const Color error = Color(0xFFB42318);
  static const Color success = Color(0xFF0F7A4A);
  static const Color info = Color(0xFF2563EB);

  static const Color surfaceLight = Color(0xFFF7FAFC);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color backgroundLight = Color(0xFFF2F6FA);
  static const Color backgroundDark = Color(0xFF07111E);
  static const Color cardDark = Color(0xFF111C2F);
  static const Color inputDark = Color(0xFF111C2F);

  static const Color neutral900 = Color(0xFF10233D);
  static const Color neutral800 = Color(0xFF23395A);
  static const Color neutral700 = Color(0xFF445C77);
  static const Color neutral600 = Color(0xFF64748B);
  static const Color neutral500 = Color(0xFF94A3B8);
  static const Color neutral400 = Color(0xFFCBD5E1);
  static const Color neutral300 = Color(0xFFE2E8F0);
  static const Color neutral200 = Color(0xFFF1F5F9);
  static const Color neutral100 = Color(0xFFF8FAFC);

  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;

  static const double radius8 = 8;
  static const double radius12 = 12;
  static const double radius16 = 16;
  static const double radius24 = 24;

  static const double elevationLow = 2;
  static const double elevationMid = 6;
  static const double elevationHigh = 12;

  static Color tripStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SCHEDULED':
      case 'REQUESTED':
      case 'ASSIGNED':
        return info;
      case 'STARTED':
      case 'IN_PROGRESS':
        return accent;
      case 'COMPLETED':
        return success;
      case 'CANCELLED':
      case 'NO_SHOW':
        return error;
      default:
        return neutral600;
    }
  }

  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
    primary: primary,
    secondary: secondary,
    tertiary: accent,
    surface: surfaceLight,
    error: error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: neutral900,
  );

  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.dark,
    primary: primary,
    secondary: secondary,
    tertiary: accent,
    surface: surfaceDark,
    error: error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: neutral100,
  );
}
