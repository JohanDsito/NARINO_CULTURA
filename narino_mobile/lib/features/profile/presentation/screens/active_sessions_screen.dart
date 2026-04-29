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

    return Scaffold(
      backgroundColor: AppColors.bgLight,
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.tierraProfunda),
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
                    color: AppColors.textMutedLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.tierraProfunda,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.devices_outlined,
                  color: AppColors.tierraProfunda),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  session.device,
                  style: AppTypography.labelSemiBold(
                    color: AppColors.textPrimaryLight,
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
                    color: AppColors.indigoPalido,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'ACTUAL',
                    style: AppTypography.caption(color: AppColors.indigoNoche),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined,
                  size: 18, color: AppColors.textMutedLight),
              const SizedBox(width: 6),
              Text(
                dateText,
                style: AppTypography.bodyMedium(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.schedule_outlined,
                  size: 18, color: AppColors.textMutedLight),
              const SizedBox(width: 6),
              Text(
                timeText,
                style: AppTypography.bodyMedium(
                  color: AppColors.textSecondaryLight,
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
                  color:
                      onClose == null ? AppColors.borderLight : AppColors.error,
                ),
              ),
              child: Text(
                onClose == null ? 'Sesión actual' : 'Cerrar esta sesión',
                style: AppTypography.labelSemiBold(
                  color: onClose == null
                      ? AppColors.textMutedLight
                      : AppColors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
