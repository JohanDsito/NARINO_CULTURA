import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'section_card.dart';

class DescriptionCard extends StatefulWidget {
  const DescriptionCard({super.key, required this.descripcion});

  final String descripcion;

  @override
  State<DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<DescriptionCard> {
  bool _expanded = false;
  static const _maxLines = 4;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final linkColor = isDark ? AppColors.tierraDark : AppColors.tierraProfunda;

    return SectionCard(
      title: 'Descripción',
      icon: Icons.notes_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedCrossFade(
            firstChild: Text(
              widget.descripcion,
              style: AppTypography.bodyMedium(color: textPrimary),
              maxLines: _maxLines,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(
              widget.descripcion,
              style: AppTypography.bodyMedium(color: textPrimary),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          if (widget.descripcion.length > 200) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Ver menos' : 'Ver más',
                style: AppTypography.caption(color: linkColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
