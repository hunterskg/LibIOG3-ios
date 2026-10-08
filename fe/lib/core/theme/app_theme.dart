import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

InputDecorationTheme _inputTheme(Color enabled, Color focus, Color error) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: AppRadius.brMd,
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecorationTheme(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    enabledBorder: border(enabled),
    border: border(enabled),
    focusedBorder: border(focus, 2),
    errorBorder: border(error),
    focusedErrorBorder: border(error, 2),
    errorStyle: AppTextStyles.caption.copyWith(color: AppColors.danger),
    hintStyle: AppTextStyles.body.copyWith(color: AppColors.charcoal400),
  );
}

ThemeData get appLightTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: AppColors.neutral50,
      colorScheme: const ColorScheme.light(
        primary: AppColors.charcoal800,
        onPrimary: AppColors.white,
        secondary: AppColors.accent500,
        surface: AppColors.white,
        onSurface: AppColors.charcoal900,
        error: AppColors.danger,
        outline: AppColors.neutral200,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.neutral200),
          borderRadius: AppRadius.brLg,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.neutral200,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme:
          _inputTheme(AppColors.neutral300, AppColors.accent500, AppColors.danger),
    );

ThemeData get appDarkTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: AppColors.charcoal900,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent500,
        onPrimary: AppColors.charcoal900,
        secondary: AppColors.accent600,
        surface: AppColors.charcoal800,
        onSurface: AppColors.neutral100,
        error: AppColors.danger,
        outline: AppColors.charcoal600,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.charcoal800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.charcoal600),
          borderRadius: AppRadius.brLg,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.charcoal600,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme:
          _inputTheme(AppColors.charcoal600, AppColors.accent500, AppColors.danger),
    );
