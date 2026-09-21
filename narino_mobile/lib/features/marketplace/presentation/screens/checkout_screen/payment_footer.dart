import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Footer de pago ───────────────────────────────────────────────────────────

class PaymentFooter extends StatelessWidget {
  const PaymentFooter({
    super.key,
    required this.totalFormateado,
    required this.itemCount,
    required this.submitting,
    required this.onPay,
  });

  final String totalFormateado;
  final int itemCount;
  final bool submitting;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: bgCard,
        border: Border(top: BorderSide(color: border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$itemCount ${itemCount == 1 ? 'obra' : 'obras'}',
                    style: AppTypography.caption(color: textMuted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    totalFormateado,
                    style: AppTypography.labelSemiBold(color: textPrimary),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: (itemCount == 0 || submitting) ? null : onPay,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              icon: submitting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.onPrimary),
                    )
                  : const Icon(Icons.credit_card_outlined),
              label: Text(
                submitting ? 'Redirigiendo...' : 'Pagar con Wompi',
                style: AppTypography.labelSemiBold(color: cs.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
