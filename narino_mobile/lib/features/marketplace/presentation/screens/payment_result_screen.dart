import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({
    super.key,
    required this.orderId,
    required this.success,
  });

  final int orderId;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final isSuccess = success;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Resultado de pago',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: (isSuccess ? Colors.green : Colors.red).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: isSuccess ? Colors.green : Colors.red,
                size: 42,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isSuccess ? 'Pago confirmado' : 'Pago no completado',
              style: AppTypography.displaySemiBold(
                  color: AppColors.textPrimaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSuccess
                  ? 'Tu orden #$orderId fue procesada correctamente.'
                  : 'No se pudo confirmar el pago de la orden #$orderId.',
              style: AppTypography.bodyMedium(color: AppColors.textMutedLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (isSuccess)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/home'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderLight),
                        foregroundColor: AppColors.textPrimaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Volver al inicio'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context.go('/marketplace/purchases'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.indigoNoche,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Ver mis compras'),
                    ),
                  ),
                ],
              )
            else
              FilledButton(
                onPressed: () => context.go('/marketplace/cart'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.indigoNoche,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: const Text('Reintentar'),
              ),
          ],
        ),
      ),
    );
  }
}
