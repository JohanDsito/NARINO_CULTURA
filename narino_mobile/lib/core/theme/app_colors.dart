import 'package:flutter/material.dart';

/// Paleta "Carnaval" del design system móvil
/// (`narino_cultura_movil_1_design_system.html`).
///
/// Colores puros y vibrantes, inspirados en las carrozas, el talco y la
/// cosmética. **No se usan pasteles**: los tonos "pálidos" heredados ahora son
/// el mismo color con transparencia.
class AppColors {
  AppColors._();

  // ─── Acentos de marca ──────────────────────────────────────────────────────
  /// Energía y alertas.
  static const Color tomate = Color(0xFFFF3300);

  /// Artesanos, marketplace y hora de los eventos.
  static const Color naranjaNeon = Color(0xFFFF6600);

  /// Música y acciones principales (modo oscuro).
  static const Color azulNeon = Color(0xFF00E5FF);

  /// Música y acciones principales (modo claro).
  static const Color azulNeonLight = Color(0xFF0055FF);

  /// Íconos y detalles premium (modo oscuro).
  static const Color oroTierra = Color(0xFFD4AF37);

  /// Íconos y detalles premium (modo claro).
  static const Color oroTierraLight = Color(0xFFB8860B);

  /// Artes plásticas (modo oscuro).
  static const Color magenta = Color(0xFFFF0055);

  /// Artes plásticas (modo claro).
  static const Color magentaLight = Color(0xFFE50050);

  /// Verde vivo para "disponible" / éxito (no está en la paleta base, pero
  /// la app lo necesita para estados).
  static const Color verdeVivo = Color(0xFF00C46A);

  // ─── "Tintas" para texto en modo claro (contraste ≥ 4.5:1 sobre #F5F5F7) ──
  // Los neón puros no se leen como texto sobre fondo claro (2.1–3.7:1).
  static const Color tomateInk = Color(0xFFC82800); // 5.1:1
  static const Color naranjaInk = Color(0xFFB34700); // 5.1:1
  static const Color oroInk = Color(0xFF8A6400); // 4.9:1
  static const Color magentaInk = Color(0xFFC8004A); // 5.4:1
  static const Color verdeInk = Color(0xFF007A47); // 5.0:1

  // ─── Superficies — modo oscuro (por defecto) ───────────────────────────────
  static const Color bgDark = Color(0xFF050505);
  static const Color bgCardDark = Color(0xFF121214);
  static const Color bgGlassDark = Color(0xB8121214); // rgba(18,18,20,.72)
  static const Color bgSubtleDark = Color(0xFF1C1C1F);
  static const Color borderDark = Color(0x14FFFFFF); // rgba(255,255,255,.08)
  static const Color textPrimaryDark = Color(0xFFF5F5F7);
  static const Color textSecondaryDark = Color(0xFF86868B);
  static const Color textMutedDark = Color(0xFF7C7C82); // 4.5:1 sobre tarjeta

  // ─── Superficies — modo claro ──────────────────────────────────────────────
  static const Color bgLight = Color(0xFFF5F5F7);
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color bgGlassLight = Color(0xC7FFFFFF); // rgba(255,255,255,.78)
  static const Color bgSubtleLight = Color(0xFFEBEBED);
  static const Color borderLight = Color(0x0F000000); // rgba(0,0,0,.06)
  static const Color textPrimaryLight = Color(0xFF1D1D1F);
  static const Color textSecondaryLight = Color(0xFF6E6E73);
  static const Color textMutedLight = Color(0xFF74747A); // 4.6:1 sobre blanco

  // ─── Semánticos ────────────────────────────────────────────────────────────
  static const Color error = tomate;
  static const Color success = verdeVivo;

  // ─── Nombres heredados (alias a la paleta nueva) ───────────────────────────
  // Se conservan para que las pantallas existentes tomen los colores nuevos
  // sin tocar cada archivo. Al rediseñar cada pantalla se reemplazan por los
  // tokens de arriba o por `context.nc` (ver `nc_theme.dart`).
  static const Color tierraProfunda = naranjaNeon;
  static const Color tierraClara = Color(0xFFFF8533);
  static const Color tierraPalida = Color(0x26FF6600);
  static const Color tierraDark = naranjaNeon;

  static const Color obsidiana = bgDark;
  static const Color volcanMedio = bgCardDark;
  static const Color nocheNarino = bgDark;

  static const Color oroAndino = oroTierraLight;
  static const Color oroClaro = oroTierra;
  static const Color oroPalido = Color(0x26D4AF37);
  static const Color oroDark = oroTierra;

  static const Color selvaAndina = verdeVivo;
  static const Color selvaClara = Color(0xFF2EE59D);
  static const Color selvaPalida = Color(0x2600C46A);
  static const Color selvaDark = Color(0xFF2EE59D);

  static const Color indigoNoche = azulNeonLight;
  static const Color indigoClaro = Color(0xFF3D8BFF);
  static const Color indigoPalido = Color(0x260055FF);
  static const Color indigoDark = azulNeon;
}
