import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material 3 type scale using Noto Sans — strong Latin + Arabic coverage for RTL.
class TransportationAppTextStyles {
  TransportationAppTextStyles._();

  static TextTheme themed(Brightness brightness) {
    final base = GoogleFonts.notoSansTextTheme();
    final color = brightness == Brightness.dark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF10233D);

    return base.copyWith(
      displayLarge: base.displayLarge
          ?.copyWith(fontWeight: FontWeight.w700, height: 1.2, color: color),
      displayMedium: base.displayMedium
          ?.copyWith(fontWeight: FontWeight.w700, height: 1.2, color: color),
      displaySmall: base.displaySmall
          ?.copyWith(fontWeight: FontWeight.w700, height: 1.2, color: color),
      headlineLarge: base.headlineLarge
          ?.copyWith(fontWeight: FontWeight.w700, height: 1.25, color: color),
      headlineMedium: base.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w700, height: 1.25, color: color),
      headlineSmall: base.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w600, height: 1.25, color: color),
      titleLarge: base.titleLarge
          ?.copyWith(fontWeight: FontWeight.w600, height: 1.3, color: color),
      titleMedium: base.titleMedium
          ?.copyWith(fontWeight: FontWeight.w600, height: 1.3, color: color),
      titleSmall: base.titleSmall
          ?.copyWith(fontWeight: FontWeight.w600, height: 1.35, color: color),
      bodyLarge: base.bodyLarge
          ?.copyWith(fontWeight: FontWeight.w400, height: 1.5, color: color),
      bodyMedium: base.bodyMedium
          ?.copyWith(fontWeight: FontWeight.w400, height: 1.5, color: color),
      bodySmall: base.bodySmall
          ?.copyWith(fontWeight: FontWeight.w400, height: 1.45, color: color),
      labelLarge: base.labelLarge
          ?.copyWith(fontWeight: FontWeight.w600, height: 1.4, color: color),
      labelMedium: base.labelMedium
          ?.copyWith(fontWeight: FontWeight.w600, height: 1.4, color: color),
      labelSmall: base.labelSmall
          ?.copyWith(fontWeight: FontWeight.w600, height: 1.4, color: color),
    );
  }
}
