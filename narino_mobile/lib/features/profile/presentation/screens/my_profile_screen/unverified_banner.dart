import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../auth/data/auth_repository.dart';

// ─── Banner correo sin verificar ─────────────────────────────────────────────

class UnverifiedBanner extends ConsumerWidget {
  const UnverifiedBanner({super.key, required this.authProvider});

  final ProviderBase<AuthRepository> authProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.oroAndino.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.oroAndino.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mail_outline,
            color: AppColors.oroAndino,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correo sin verificar',
                  style: AppTypography.labelSemiBold(
                    color: AppColors.oroAndino,
                  ),
                ),
                Text(
                  'Verifica tu correo para acceso completo.',
                  style: AppTypography.caption(color: AppColors.oroAndino),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(authProvider).resendVerification();
                if (!context.mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Correo de verificación enviado ✅'),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(
              'Reenviar',
              style: AppTypography.caption(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
