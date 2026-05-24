import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

// ─── Disciplinas disponibles ─────────────────────────────────────────────────

class _Discipline {
  const _Discipline({
    required this.label,
    required this.value,
    required this.icon,
    required this.description,
  });

  final String label;
  final String value;
  final IconData icon;
  final String description;
}

const _kDisciplines = <_Discipline>[
  _Discipline(
    label: 'Artesano',
    value: 'Artesano',
    icon: Icons.content_cut_outlined,
    description: 'Objetos únicos con técnicas tradicionales',
  ),
  _Discipline(
    label: 'Fotógrafo',
    value: 'Fotógrafo',
    icon: Icons.camera_alt_outlined,
    description: 'Captura momentos y paisajes del territorio',
  ),
  _Discipline(
    label: 'Escultor',
    value: 'Escultor',
    icon: Icons.architecture_outlined,
    description: 'Formas tridimensionales en diferentes materiales',
  ),
  _Discipline(
    label: 'Pintor',
    value: 'Pintor',
    icon: Icons.brush_outlined,
    description: 'Expresión visual sobre lienzo u otras superficies',
  ),
  _Discipline(
    label: 'Músico',
    value: 'Músico',
    icon: Icons.music_note_outlined,
    description: 'Composición, interpretación y producción musical',
  ),
];

// ─── Pantalla ────────────────────────────────────────────────────────────────

class ArtisticProfileScreen extends StatefulWidget {
  const ArtisticProfileScreen({super.key});

  @override
  State<ArtisticProfileScreen> createState() => _ArtisticProfileScreenState();
}

class _ArtisticProfileScreenState extends State<ArtisticProfileScreen> {
  String? _selected;
  bool _isLoading = false;
  String? _error;

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final me = await ApiClient.instance.dio.get('/api/v1/artists/me/');
      final slug = (me.data as Map<String, dynamic>)['slug'] as String;
      await ApiClient.instance.dio
          .patch('/api/v1/artists/$slug/', data: {'discipline': _selected});
      if (mounted) context.go('/home');
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'No se pudo guardar el perfil. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: AppColors.obsidiana,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.oroAndino,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.palette_outlined,
                            size: 22, color: AppColors.obsidiana),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Nariño Cultura',
                        style: AppTypography.displayBold(
                                color: AppColors.oroClaro)
                            .copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '¿Cuál es tu perfil artístico?',
                    style: AppTypography.displaySemiBold(
                        color: AppColors.oroClaro),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Elige la disciplina que mejor te describe.',
                    style: AppTypography.quoteItalic(
                      color: AppColors.oroClaro.withAlpha(160),
                    ),
                  ),
                ],
              ),
            ),

            // ── Lista de disciplinas ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  children: [
                    for (final d in _kDisciplines) ...[
                      _DisciplineCard(
                        discipline: d,
                        isSelected: _selected == d.value,
                        disabled: _isLoading,
                        onTap: () => setState(() => _selected = d.value),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      _ErrorBanner(message: _error!),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed:
                            (_selected == null || _isLoading) ? null : _confirm,
                        child: _isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : const Text('Continuar'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => context.go('/home'),
                      child: Text(
                        'Completar más tarde',
                        style: AppTypography.bodySmall(color: textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tarjeta de disciplina ────────────────────────────────────────────────────

class _DisciplineCard extends StatelessWidget {
  const _DisciplineCard({
    required this.discipline,
    required this.isSelected,
    required this.disabled,
    required this.onTap,
  });

  final _Discipline discipline;
  final bool isSelected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final selectedBg =
        isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? cs.primary : border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.12)
                    : (isDark
                        ? AppColors.bgSubtleDark
                        : AppColors.bgSubtleLight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                discipline.icon,
                size: 24,
                color: isSelected ? cs.primary : textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    discipline.label,
                    style: AppTypography.labelSemiBold(
                      color: isSelected ? cs.primary : textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    discipline.description,
                    style: AppTypography.caption(color: textMuted),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(Icons.check_circle, color: cs.primary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Banner de error ──────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall(color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
