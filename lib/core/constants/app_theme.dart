import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      fontFamily: 'Roboto',

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        centerTitle: false,
      ),

      // FloatingActionButton theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.textWhite,
        foregroundColor: AppColors.black,
        shape: CircleBorder(),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: AppColors.textWhite),

      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textWhite,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: AppColors.textWhite,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textWhite,
          fontSize: 16,
          height: 1.6,
        ),
      ),

      colorScheme: const ColorScheme.dark(
        surface: AppColors.scaffoldBg,
        primary: AppColors.textWhite,
      ),
    );
  }
}
