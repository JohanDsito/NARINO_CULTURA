import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/nc_theme.dart';

/// Botón primario (`.btn-primary`): píldora azul de 48 px con brillo en
/// oscuro. Muestra un indicador mientras [loading] es `true`.
class NcPrimaryButton extends StatelessWidget {
  const NcPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(nc.onAzul),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        boxShadow: onPressed == null ? null : nc.glow,
      ),
      child: ElevatedButton(
        onPressed: loading ? () {} : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 50),
        ),
        child: Semantics(
          label: loading ? '$label, cargando' : null,
          child: child,
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Botón secundario (`.btn-secondary`): píldora translúcida con borde.
class NcSecondaryButton extends StatelessWidget {
  const NcSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 50)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Aviso en línea con el color de un acento (error, éxito, info…).
class NcBanner extends StatelessWidget {
  const NcBanner({
    super.key,
    required this.message,
    required this.accent,
    this.icon = Icons.info_outline_rounded,
  });

  /// Atajo para errores (tomate).
  factory NcBanner.error(BuildContext context, String message) => NcBanner(
        message: message,
        accent: context.nc.tomateA,
        icon: Icons.error_outline_rounded,
      );

  /// Atajo para confirmaciones (verde).
  factory NcBanner.success(BuildContext context, String message) => NcBanner(
        message: message,
        accent: context.nc.successA,
        icon: Icons.check_circle_outline_rounded,
      );

  final String message;
  final NcAccent accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: accent.tint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.fill.withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent.ink, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium(color: nc.textPrimary)
                    .copyWith(fontSize: 13.5, height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícono dentro de un círculo teñido con el color del acento.
class NcAccentIcon extends StatelessWidget {
  const NcAccentIcon({
    super.key,
    required this.icon,
    required this.accent,
    this.size = 44,
    this.glow = false,
  });

  final IconData icon;
  final NcAccent accent;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.tint,
        shape: BoxShape.circle,
        border: Border.all(color: accent.fill.withValues(alpha: 0.4)),
        boxShadow: glow ? nc.tintedShadow(accent.fill) : null,
      ),
      child: Icon(icon, color: accent.ink, size: size * 0.48),
    );
  }
}

/// Franja "serpentina" con el degradado carnaval completo.
class NcSerpentina extends StatelessWidget {
  const NcSerpentina({super.key, this.width = 64, this.height = 4});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: context.nc.carnavalGradient,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}
