import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        // Sin botón de back — estado terminal del flujo de pago
        automaticallyImplyLeading: false,
        title: Text(
          'Resultado de pago',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: success
              ? _SuccessContent(orderId: orderId)
              : _FailureContent(orderId: orderId),
        ),
      ),
    );
  }
}

// ─── Estado de éxito ──────────────────────────────────────────────────────────

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _ResultIcon(
          icon: Icons.check_circle_outline,
          color: AppColors.selvaAndina,
          background: AppColors.selvaPalida,
        ),
        const SizedBox(height: 20),
        Text(
          '¡Pago confirmado!',
          style: AppTypography.displaySemiBold(color: textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'La orden #$orderId fue procesada correctamente. Recibirás un comprobante por correo.',
          style: AppTypography.bodyMedium(color: textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: border),
                  foregroundColor: textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Ir al inicio'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.go('/marketplace/purchases'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Mis compras'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Estado de error ──────────────────────────────────────────────────────────

class _FailureContent extends StatelessWidget {
  const _FailureContent({required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ResultIcon(
          icon: Icons.error_outline,
          color: AppColors.error,
          background: AppColors.error.withAlpha(10),
        ),
        const SizedBox(height: 20),
        Text(
          'Pago no completado',
          style: AppTypography.displaySemiBold(color: textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'No se pudo confirmar el pago de la orden #$orderId. Puedes reintentar o revisar tu método de pago.',
          style: AppTypography.bodyMedium(color: textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: border),
                  foregroundColor: textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Ir al inicio'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.go('/marketplace/cart'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.refresh_outlined, size: 18),
                label: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Ícono de resultado ───────────────────────────────────────────────────────

class _ResultIcon extends StatelessWidget {
  const _ResultIcon({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 44),
    );
  }
}
