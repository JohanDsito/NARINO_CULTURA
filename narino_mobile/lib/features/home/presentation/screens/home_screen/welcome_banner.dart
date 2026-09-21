import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Banner de bienvenida ─────────────────────────────────────────────────────

class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF180E00),
            AppColors.obsidiana,
            Color(0xFF3C2008),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Círculo decorativo grande — arriba derecha
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.oroAndino.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Círculo más pequeño — abajo derecha
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tierraProfunda.withValues(alpha: 0.18),
              ),
            ),
          ),
          // Línea de acento dorada vertical — izquierda
          Positioned(
            left: 0,
            top: 16,
            bottom: 16,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.oroAndino.withValues(alpha: 0),
                    AppColors.oroClaro,
                    AppColors.oroAndino,
                    AppColors.oroAndino.withValues(alpha: 0),
                  ],
                ),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          // Contenido principal
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Etiqueta de categoría
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.oroAndino.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: AppColors.oroAndino.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    '✦  Arte & Cultura · Nariño',
                    style: AppTypography.caption(color: AppColors.oroClaro),
                  ),
                ),
                const SizedBox(height: 14),
                // Titular principal
                Text(
                  'Descubre el arte\nde tu región',
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w700,
                    fontSize: 30,
                    height: 1.18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                // Subtítulo
                Text(
                  'Pinturas · Esculturas · Artesanías · Más',
                  style: AppTypography.bodySmall(
                    color: AppColors.oroClaro.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          // Línea de acento dorada inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.oroAndino.withValues(alpha: 0),
                    AppColors.oroClaro,
                    AppColors.oroAndino,
                    AppColors.oroAndino.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
