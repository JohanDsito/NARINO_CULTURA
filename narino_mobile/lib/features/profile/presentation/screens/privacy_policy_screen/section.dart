import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

// ─── Componentes reutilizables ────────────────────────────────────────────────

class PolicySection extends StatelessWidget {
  const PolicySection({
    super.key,
    required this.title,
    required this.children,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.bgSubtle,
  });

  final String title;
  final List<Widget> children;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color bgSubtle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.labelSemiBold(color: textPrimary)
                  .copyWith(fontSize: 14)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
