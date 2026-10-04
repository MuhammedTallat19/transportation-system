import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData light() =>
      _build(TransportationAppDesignTokens.lightColorScheme, Brightness.light);
  static ThemeData dark() =>
      _build(TransportationAppDesignTokens.darkColorScheme, Brightness.dark);

  static ThemeData _build(ColorScheme cs, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textTheme = TransportationAppTextStyles.themed(brightness);
    final cardColor =
        isDark ? TransportationAppDesignTokens.cardDark : Colors.white;
    final inputFill =
        isDark ? TransportationAppDesignTokens.inputDark : Colors.white;
    final borderColor = isDark
        ? TransportationAppDesignTokens.neutral700
        : TransportationAppDesignTokens.neutral300;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: isDark
          ? TransportationAppDesignTokens.backgroundDark
          : TransportationAppDesignTokens.backgroundLight,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(
            color: isDark
                ? TransportationAppDesignTokens.neutral100
                : TransportationAppDesignTokens.neutral900),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(TransportationAppDesignTokens.radius16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: TransportationAppDesignTokens.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: TransportationAppDesignTokens.neutral400,
          padding: const EdgeInsets.symmetric(
              horizontal: TransportationAppDesignTokens.space16, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  TransportationAppDesignTokens.radius12)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark
              ? TransportationAppDesignTokens.neutral100
              : TransportationAppDesignTokens.primary,
          padding: const EdgeInsets.symmetric(
              horizontal: TransportationAppDesignTokens.space16, vertical: 14),
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  TransportationAppDesignTokens.radius12)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TransportationAppDesignTokens.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: TransportationAppDesignTokens.space16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(TransportationAppDesignTokens.radius12),
            borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(TransportationAppDesignTokens.radius12),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(TransportationAppDesignTokens.radius12),
            borderSide: const BorderSide(
                color: TransportationAppDesignTokens.primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(TransportationAppDesignTokens.radius12),
            borderSide:
                const BorderSide(color: TransportationAppDesignTokens.error)),
        labelStyle: textTheme.bodyMedium
            ?.copyWith(color: TransportationAppDesignTokens.neutral600),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? TransportationAppDesignTokens.neutral800
            : TransportationAppDesignTokens.neutral200,
        selectedColor: TransportationAppDesignTokens.primary.withOpacity(0.15),
        labelStyle: textTheme.labelMedium!,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(TransportationAppDesignTokens.radius8)),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(TransportationAppDesignTokens.radius16)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? TransportationAppDesignTokens.neutral800
            : TransportationAppDesignTokens.neutral900,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(TransportationAppDesignTokens.radius12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(TransportationAppDesignTokens.radius24)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: TransportationAppDesignTokens.primary
            .withOpacity(isDark ? 0.18 : 0.12),
        labelTextStyle:
            WidgetStateProperty.resolveWith((_) => textTheme.labelMedium),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
                color: TransportationAppDesignTokens.primary, size: 24);
          }
          return IconThemeData(
              color: TransportationAppDesignTokens.neutral600, size: 24);
        }),
      ),
      dividerTheme: DividerThemeData(color: borderColor, thickness: 1),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: TransportationAppDesignTokens.primary,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: TransportationAppDesignTokens.primary),
    );
  }
}
