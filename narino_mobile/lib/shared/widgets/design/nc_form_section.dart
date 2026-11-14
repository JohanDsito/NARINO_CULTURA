import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/nc_theme.dart';
import 'nc_card.dart';

/// Tarjeta de un bloque de formulario: título, ayuda opcional y campos.
class NcFormSection extends StatelessWidget {
  const NcFormSection({
    super.key,
    required this.title,
    required this.children,
    this.hint,
  });

  final String title;
  final String? hint;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return NcCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title,
                      style:
                          AppTypography.labelSemiBold(color: nc.textPrimary)),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(hint!,
                      style: AppTypography.bodySmall(color: nc.textSecondary)),
                ],
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
