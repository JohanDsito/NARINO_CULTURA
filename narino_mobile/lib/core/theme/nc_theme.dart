import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Un color de acento del carnaval con sus cuatro usos.
///
/// - [fill]: relleno neón (botones, chips activos, insignias).
/// - [onFill]: texto/ícono sobre [fill] (negro en los neón cálidos, como las
///   letras de las carrozas; blanco sobre magenta y sobre el azul claro).
/// - [ink]: el color usado como TEXTO sobre el fondo. En modo claro es una
///   versión más oscura para cumplir contraste ≥ 4.5:1.
/// - [tint]: fondo suave del color (16 % en oscuro, 10 % en claro).
@immutable
class NcAccent {
  const NcAccent({
    required this.fill,
    required this.onFill,
    required this.ink,
    required this.tint,
  });

  final Color fill;
  final Color onFill;
  final Color ink;
  final Color tint;
}

/// Tokens del design system "Carnaval" que cambian entre modo claro y oscuro.
///
/// Uso: `final nc = context.nc;` y luego `nc.azul`, `nc.tienda.ink`,
/// `nc.carnavalGradient`…
///
/// Reglas de combinación (ver `docs/DISENO_CARNAVAL.md`):
/// - La acción principal SIEMPRE es azul.
/// - Cada sección tiene su acento: catálogo magenta, tienda naranja,
///   subastas oro (+ tomate para "en vivo"), eventos tomate, música azul,
///   perfil la serpentina completa.
/// - Texto de color → `ink`. Relleno → `fill` + `onFill`. Fondo → `tint`.
@immutable
class NcColors extends ThemeExtension<NcColors> {
  const NcColors({
    required this.isDark,
    required this.bg,
    required this.bgCard,
    required this.bgGlass,
    required this.bgSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.azul,
    required this.onAzul,
    required this.tomateA,
    required this.naranjaA,
    required this.oroA,
    required this.magentaA,
    required this.successA,
  });

  final bool isDark;
  final Color bg;
  final Color bgCard;
  final Color bgGlass;
  final Color bgSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;

  /// Acción principal (botones, links, pestaña activa, foco).
  final Color azul;
  final Color onAzul;

  final NcAccent tomateA;
  final NcAccent naranjaA;
  final NcAccent oroA;
  final NcAccent magentaA;
  final NcAccent successA;

  NcAccent get azulA => NcAccent(
        fill: azul,
        onFill: onAzul,
        ink: azul,
        tint: azul.withValues(alpha: isDark ? 0.14 : 0.10),
      );

  // ── Atajos (relleno neón) — para decoración, rellenos y bordes ──
  Color get tomate => tomateA.fill;
  Color get naranja => naranjaA.fill;
  Color get oro => oroA.fill;
  Color get magenta => magentaA.fill;
  Color get success => successA.fill;
  Color get error => tomateA.fill;

  // ── Acentos por sección ──
  NcAccent get catalogo => magentaA;
  NcAccent get tienda => naranjaA;
  NcAccent get subastas => oroA;
  NcAccent get enVivo => tomateA;
  NcAccent get eventos => tomateA;
  NcAccent get musica => azulA;

  /// Fondo de ítems de lista suaves (agenda, filas): blanco 3 % / negro 2 %.
  Color get itemFill => isDark
      ? Colors.white.withValues(alpha: 0.03)
      : Colors.black.withValues(alpha: 0.02);

  /// Fondo del botón secundario: blanco 10 % / negro 5 %.
  Color get secondaryFill => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.black.withValues(alpha: 0.05);

  /// Sombra estándar de tarjetas.
  List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.05),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ];

  /// Sombra de color (en claro da el toque festivo sin perder limpieza).
  List<BoxShadow> tintedShadow(Color c) => [
        BoxShadow(
          color: c.withValues(alpha: isDark ? 0.22 : 0.12),
          blurRadius: 22,
          spreadRadius: -4,
        ),
      ];

  /// Brillo neón del botón primario (solo en oscuro).
  List<BoxShadow> get glow => isDark
      ? [
          BoxShadow(
            color: AppColors.azulNeon.withValues(alpha: 0.3),
            blurRadius: 20,
          ),
        ]
      : const [];

  /// Borde de tarjetas en oscuro (azul → naranja), tal cual el diseño.
  LinearGradient get borderGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.azulNeon, AppColors.naranjaNeon],
      );

  /// Logo (naranja → magenta).
  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.naranjaNeon, magenta],
      );

  /// "Serpentina": tomate → naranja → oro → magenta → azul. Para franjas,
  /// anillos de avatar y detalles festivos (nunca detrás de texto).
  LinearGradient get carnavalGradient => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppColors.tomate,
          AppColors.naranjaNeon,
          oro,
          magenta,
          azul,
        ],
      );

  /// Degradado cálido para héroes y banners (tomate → magenta).
  LinearGradient get fiestaGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.tomate, magenta],
      );

  /// Texto de título con degradado (oscuro): blanco → azul neón.
  LinearGradient get titleGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, AppColors.azulNeon],
      );

  static const dark = NcColors(
    isDark: true,
    bg: AppColors.bgDark,
    bgCard: AppColors.bgCardDark,
    bgGlass: AppColors.bgGlassDark,
    bgSubtle: AppColors.bgSubtleDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textMuted: AppColors.textMutedDark,
    border: AppColors.borderDark,
    azul: AppColors.azulNeon,
    onAzul: Colors.black,
    tomateA: NcAccent(
      fill: AppColors.tomate,
      onFill: Colors.black,
      ink: AppColors.tomate,
      tint: Color(0x29FF3300),
    ),
    naranjaA: NcAccent(
      fill: AppColors.naranjaNeon,
      onFill: Colors.black,
      ink: AppColors.naranjaNeon,
      tint: Color(0x29FF6600),
    ),
    oroA: NcAccent(
      fill: AppColors.oroTierra,
      onFill: Colors.black,
      ink: AppColors.oroTierra,
      tint: Color(0x29D4AF37),
    ),
    magentaA: NcAccent(
      fill: AppColors.magentaLight, // con blanco encima cumple 4.7:1
      onFill: Colors.white,
      ink: AppColors.magenta,
      tint: Color(0x29FF0055),
    ),
    successA: NcAccent(
      fill: AppColors.verdeVivo,
      onFill: Colors.black,
      ink: AppColors.verdeVivo,
      tint: Color(0x2900C46A),
    ),
  );

  static const light = NcColors(
    isDark: false,
    bg: AppColors.bgLight,
    bgCard: AppColors.bgCardLight,
    bgGlass: AppColors.bgGlassLight,
    bgSubtle: AppColors.bgSubtleLight,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    textMuted: AppColors.textMutedLight,
    border: AppColors.borderLight,
    azul: AppColors.azulNeonLight,
    onAzul: Colors.white,
    tomateA: NcAccent(
      fill: AppColors.tomate,
      onFill: Colors.black,
      ink: AppColors.tomateInk,
      tint: Color(0x1AFF3300),
    ),
    naranjaA: NcAccent(
      fill: AppColors.naranjaNeon,
      onFill: Colors.black,
      ink: AppColors.naranjaInk,
      tint: Color(0x1AFF6600),
    ),
    oroA: NcAccent(
      fill: AppColors.oroTierra,
      onFill: Colors.black,
      ink: AppColors.oroInk,
      tint: Color(0x1FD4AF37),
    ),
    magentaA: NcAccent(
      fill: AppColors.magentaLight,
      onFill: Colors.white,
      ink: AppColors.magentaInk,
      tint: Color(0x1AE50050),
    ),
    successA: NcAccent(
      fill: AppColors.verdeVivo,
      onFill: Colors.black,
      ink: AppColors.verdeInk,
      tint: Color(0x1A00C46A),
    ),
  );

  @override
  NcColors copyWith() => this;

  @override
  NcColors lerp(ThemeExtension<NcColors>? other, double t) {
    if (other is! NcColors) return this;
    return t < 0.5 ? this : other;
  }
}

extension NcThemeX on BuildContext {
  /// Tokens del design system para el modo actual.
  NcColors get nc =>
      Theme.of(this).extension<NcColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? NcColors.dark
          : NcColors.light);
}
