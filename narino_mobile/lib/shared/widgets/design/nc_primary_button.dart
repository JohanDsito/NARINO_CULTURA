import 'package:flutter/material.dart';
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
