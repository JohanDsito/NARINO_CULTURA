import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Hero reutilizable para las pantallas de auth.
/// [compact] reduce el tamaño cuando hay menos espacio vertical.
class AuthHero extends StatelessWidget {
  const AuthHero({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.obsidiana,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 44 : 72,
                height: compact ? 44 : 72,
                decoration: BoxDecoration(
                  color: AppColors.oroAndino,
                  borderRadius: BorderRadius.circular(compact ? 10 : 18),
                ),
                child: Icon(
                  Icons.landscape_outlined,
                  color: AppColors.obsidiana,
                  size: compact ? 22 : 40,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nariño Cultura',
                style: compact
                    ? AppTypography.labelSemiBold(color: AppColors.oroClaro)
                    : AppTypography.displayBold(color: AppColors.oroClaro),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
