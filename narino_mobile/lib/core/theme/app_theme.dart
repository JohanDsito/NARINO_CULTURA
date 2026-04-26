import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bgLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.tierraProfunda,
          secondary: AppColors.oroAndino,
          tertiary: AppColors.selvaAndina,
          error: AppColors.error,
          surface: AppColors.bgCardLight,
          onPrimary: Colors.white,
          onSecondary: AppColors.obsidiana,
          onSurface: AppColors.textPrimaryLight,
        ),
        textTheme: GoogleFonts.dmSansTextTheme().copyWith(
          displayLarge: AppTypography.displayBlack(),
          displayMedium: AppTypography.displayBold(),
          displaySmall: AppTypography.displaySemiBold(),
          bodyLarge: AppTypography.bodyLarge(),
          bodyMedium: AppTypography.bodyMedium(),
          bodySmall: AppTypography.bodySmall(),
          labelLarge: AppTypography.labelSemiBold(),
          labelMedium: AppTypography.labelMedium(),
          labelSmall: AppTypography.caption(),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.obsidiana,
          foregroundColor: AppColors.oroClaro,
          elevation: 0,
          centerTitle: false,
          titleTextStyle:
              AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.tierraProfunda,
            foregroundColor: Colors.white,
            textStyle: AppTypography.buttonText(),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.tierraProfunda,
            side: const BorderSide(color: AppColors.tierraProfunda, width: 1.5),
            textStyle: AppTypography.buttonText(),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bgSubtleLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.tierraProfunda, width: 1.5),
          ),
          labelStyle: AppTypography.bodyMedium(color: AppColors.textMutedLight),
          hintStyle: AppTypography.bodyMedium(color: AppColors.textMutedLight),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.tierraPalida,
          labelStyle: AppTypography.caption(color: AppColors.tierraProfunda),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
          side: BorderSide.none,
        ),
        cardTheme: CardThemeData(
          color: AppColors.bgCardLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.borderLight),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.bgCardLight,
          selectedItemColor: AppColors.tierraProfunda,
          unselectedItemColor: AppColors.textMutedLight,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.tierraDark,
          secondary: AppColors.oroDark,
          tertiary: AppColors.selvaDark,
          error: Color(0xFFE55A4A),
          surface: AppColors.bgCardDark,
          onPrimary: Colors.white,
          onSecondary: AppColors.obsidiana,
          onSurface: AppColors.textPrimaryDark,
        ),
        textTheme:
            GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge:
              AppTypography.displayBlack(color: AppColors.textPrimaryDark),
          displayMedium:
              AppTypography.displayBold(color: AppColors.textPrimaryDark),
          displaySmall:
              AppTypography.displaySemiBold(color: AppColors.textPrimaryDark),
          bodyLarge:
              AppTypography.bodyLarge(color: AppColors.textSecondaryDark),
          bodyMedium:
              AppTypography.bodyMedium(color: AppColors.textSecondaryDark),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0A0804),
          foregroundColor: AppColors.oroClaro,
          elevation: 0,
          centerTitle: false,
          titleTextStyle:
              AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.tierraDark,
            foregroundColor: Colors.white,
            textStyle: AppTypography.buttonText(),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.bgCardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.borderDark),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.bgCardDark,
          selectedItemColor: AppColors.tierraDark,
          unselectedItemColor: AppColors.textMutedDark,
          type: BottomNavigationBarType.fixed,
        ),
      );
}
