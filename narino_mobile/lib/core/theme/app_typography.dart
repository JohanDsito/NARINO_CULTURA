import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografía del design system móvil: **Inter** 300–800, limpia y geométrica.
/// Títulos en 800 con letter-spacing negativo (-0.04em), al estilo Apple.
class AppTypography {
  AppTypography._();

  static TextStyle _inter({
    required FontWeight weight,
    required double size,
    double? height,
    double em = 0,
    FontStyle? style,
    Color? color,
  }) =>
      GoogleFonts.inter(
        fontWeight: weight,
        fontSize: size,
        height: height,
        letterSpacing: em * size,
        fontStyle: style,
        color: color,
      );

  /// Hero / H1 — 34/800, -0.04em.
  static TextStyle displayBlack({Color? color}) => _inter(
      weight: FontWeight.w800, size: 34, height: 1.08, em: -0.04, color: color);

  /// Título de sección — 24/800, -0.03em.
  static TextStyle displayBold({Color? color}) => _inter(
      weight: FontWeight.w800, size: 24, height: 1.15, em: -0.03, color: color);

  /// Título de tarjeta / pantalla — 19/700, -0.02em.
  static TextStyle displaySemiBold({Color? color}) => _inter(
      weight: FontWeight.w700, size: 19, height: 1.25, em: -0.02, color: color);

  /// Citas y subtítulos decorativos.
  static TextStyle quoteItalic({Color? color}) => _inter(
      weight: FontWeight.w300,
      size: 18,
      height: 1.45,
      style: FontStyle.italic,
      color: color);

  static TextStyle quoteSemiBold({Color? color}) => _inter(
      weight: FontWeight.w600, size: 17, height: 1.35, em: -0.01, color: color);

  static TextStyle bodyLarge({Color? color}) =>
      _inter(weight: FontWeight.w400, size: 16, height: 1.6, color: color);

  static TextStyle bodyMedium({Color? color}) =>
      _inter(weight: FontWeight.w400, size: 14, height: 1.55, color: color);

  static TextStyle bodySmall({Color? color}) =>
      _inter(weight: FontWeight.w400, size: 12.5, height: 1.45, color: color);

  static TextStyle labelSemiBold({Color? color}) => _inter(
      weight: FontWeight.w600, size: 15, height: 1.3, em: -0.01, color: color);

  static TextStyle labelMedium({Color? color}) =>
      _inter(weight: FontWeight.w500, size: 13, height: 1.25, color: color);

  /// Metadatos, chips y etiquetas — 11/600.
  static TextStyle caption({Color? color}) => _inter(
      weight: FontWeight.w600, size: 11, height: 1.3, em: 0.02, color: color);

  /// Hora/fecha de agenda — 12/700 (en naranja neón).
  static TextStyle eventTime({Color? color}) =>
      _inter(weight: FontWeight.w700, size: 12, height: 1.2, color: color);

  /// Kicker del hero — 13/700, +0.04em (en oro tierra).
  static TextStyle kicker({Color? color}) => _inter(
      weight: FontWeight.w700, size: 13, height: 1.2, em: 0.04, color: color);

  static TextStyle buttonText({Color? color}) =>
      _inter(weight: FontWeight.w600, size: 15, height: 1.0, color: color);

  static TextStyle price({Color? color}) => _inter(
      weight: FontWeight.w800, size: 20, height: 1.0, em: -0.02, color: color);
}
