import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle displayBlack({Color? color}) => GoogleFonts.playfairDisplay(
        fontWeight: FontWeight.w900,
        fontSize: 36,
        height: 1.05,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle displayBold({Color? color}) => GoogleFonts.playfairDisplay(
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 1.1,
        color: color,
      );

  static TextStyle displaySemiBold({Color? color}) =>
      GoogleFonts.playfairDisplay(
        fontWeight: FontWeight.w600,
        fontSize: 22,
        height: 1.2,
        color: color,
      );

  static TextStyle quoteItalic({Color? color}) => GoogleFonts.cormorantGaramond(
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.italic,
        fontSize: 20,
        height: 1.4,
        color: color,
      );

  static TextStyle quoteSemiBold({Color? color}) =>
      GoogleFonts.cormorantGaramond(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        height: 1.3,
        color: color,
      );

  static TextStyle bodyLarge({Color? color}) => GoogleFonts.dmSans(
      fontWeight: FontWeight.w400, fontSize: 16, height: 1.6, color: color);

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.dmSans(
      fontWeight: FontWeight.w400, fontSize: 14, height: 1.55, color: color);

  static TextStyle bodySmall({Color? color}) => GoogleFonts.dmSans(
      fontWeight: FontWeight.w400, fontSize: 12, height: 1.5, color: color);

  static TextStyle labelSemiBold({Color? color}) => GoogleFonts.dmSans(
      fontWeight: FontWeight.w600, fontSize: 14, height: 1.2, color: color);

  static TextStyle labelMedium({Color? color}) => GoogleFonts.dmSans(
      fontWeight: FontWeight.w500, fontSize: 13, height: 1.2, color: color);

  static TextStyle caption({Color? color}) => GoogleFonts.dmSans(
        fontWeight: FontWeight.w500,
        fontSize: 11,
        height: 1.3,
        letterSpacing: 0.08,
        color: color,
      );

  static TextStyle buttonText({Color? color}) => GoogleFonts.dmSans(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.0,
        letterSpacing: 0.02,
        color: color,
      );

  static TextStyle price({Color? color}) => GoogleFonts.dmSans(
      fontWeight: FontWeight.w700, fontSize: 20, height: 1.0, color: color);
}
