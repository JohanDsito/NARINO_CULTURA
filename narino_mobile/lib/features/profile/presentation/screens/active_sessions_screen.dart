import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/account_security_repository.dart';
import '../providers/account_security_provider.dart';

class ActiveSessionsScreen extends ConsumerWidget {
  const ActiveSessionsScreen({super.key});

  String _formatDate(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);
  String _formatTime(DateTime dt) => DateFormat('HH:mm').format(dt);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeSessionsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Sesiones activas',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        actions: [
          TextButton(
            onPressed: state.isLoading
                ? null
                : () => ref
                    .read(activeSessionsProvider.notifier)
                    .revokeOtherSessions(),
            child: Text(
              'Cerrar otras',
              style: AppTypography.labelSemiBold(color: AppColors.oroClaro),
            ),
          ),
        ],
      ),
      body: state.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    e.toString(),
                    style: AppTypography.bodySmall(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(activeSessionsProvider.notifier).load(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No hay sesiones activas para mostrar.',
                  style: AppTypography.bodyMedium(
                    color: textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: cs.primary,
            onRefresh: () async {
              await ref.read(activeSessionsProvider.notifier).load();
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _SessionCard(
                session: sessions[i],
                onClose: sessions[i].isCurrent
                    ? null
                    : () => ref
                        .read(activeSessionsProvider.notifier)
                        .revokeSession(sessions[i].id),
                dateText: _formatDate(sessions[i].createdAt),
                timeText: _formatTime(sessions[i].createdAt),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onClose,
    required this.dateText,
    required this.timeText,
  });

  final ActiveSessionModel session;
  final VoidCallback? onClose;
  final String dateText;
  final String timeText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final currentBg = isDark
        ? AppColors.indigoNoche.withValues(alpha: 0.25)
        : AppColors.indigoPalido;
    final currentFg = isDark ? AppColors.indigoDark : AppColors.indigoNoche;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.devices_outlined, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  session.device,
                  style: AppTypography.labelSemiBold(
                    color: textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (session.isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: currentBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'ACTUAL',
                    style: AppTypography.caption(color: currentFg),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 18, color: textMuted),
              const SizedBox(width: 6),
              Text(
                dateText,
                style: AppTypography.bodyMedium(
                  color: textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Icon(Icons.schedule_outlined, size: 18, color: textMuted),
              const SizedBox(width: 6),
              Text(
                timeText,
                style: AppTypography.bodyMedium(
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                  color: onClose == null ? border : AppColors.error,
                ),
              ),
              child: Text(
                onClose == null ? 'Sesión actual' : 'Cerrar esta sesión',
                style: AppTypography.labelSemiBold(
                  color: onClose == null ? textMuted : AppColors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
