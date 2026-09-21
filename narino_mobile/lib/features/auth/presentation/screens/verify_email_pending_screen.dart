import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';
import 'verify_email_pending_screen/resent_banner.dart';
import 'verify_email_pending_screen/step.dart';

class VerifyEmailPendingScreen extends ConsumerStatefulWidget {
  const VerifyEmailPendingScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailPendingScreen> createState() =>
      _VerifyEmailPendingScreenState();
}

class _VerifyEmailPendingScreenState
    extends ConsumerState<VerifyEmailPendingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool _resending = false;
  bool _resent = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_resending || _resent) return;
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).resendVerification();
      if (mounted) setState(() { _resending = false; _resent = true; });
    } catch (_) {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final surfaceColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: AppColors.obsidiana,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
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
                    'Revisa tu correo',
                    style: AppTypography.displaySemiBold(
                        color: AppColors.oroClaro),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Un paso más y estarás dentro',
                    style: AppTypography.quoteItalic(
                      color: AppColors.oroClaro.withAlpha(160),
                    ),
                  ),
                ],
              ),
            ),

            // ── Contenido ─────────────────────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      children: [
                        // Ícono central
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.oroAndino.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  AppColors.oroAndino.withValues(alpha: 0.30),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.mark_email_unread_outlined,
                            size: 44,
                            color: AppColors.oroAndino,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Título
                        Text(
                          '¡Cuenta creada con éxito!',
                          textAlign: TextAlign.center,
                          style: AppTypography.displaySemiBold(
                              color: textPrimary),
                        ),
                        const SizedBox(height: 12),

                        // Descripción
                        Text(
                          'Te enviamos un enlace de verificación a:',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium(color: textMuted),
                        ),
                        const SizedBox(height: 10),

                        // Email pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.email_outlined,
                                  size: 16, color: textMuted),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.email,
                                  style: AppTypography.labelSemiBold(
                                      color: textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Instrucción
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              VerifyStep(
                                number: '1',
                                text:
                                    'Abre tu aplicación de correo electrónico.',
                                textColor: textPrimary,
                                mutedColor: textMuted,
                              ),
                              const SizedBox(height: 10),
                              VerifyStep(
                                number: '2',
                                text:
                                    'Busca el correo de Nariño Cultura y haz clic en "Verificar mi cuenta".',
                                textColor: textPrimary,
                                mutedColor: textMuted,
                              ),
                              const SizedBox(height: 10),
                              VerifyStep(
                                number: '3',
                                text:
                                    'Regresa aquí e inicia sesión con tu correo y contraseña.',
                                textColor: textPrimary,
                                mutedColor: textMuted,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Botón principal
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: () => context.go('/login'),
                            icon: const Icon(Icons.login_rounded, size: 20),
                            label: const Text('Ir a iniciar sesión'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Reenviar correo
                        if (_resent)
                          ResentBanner(textPrimary: textPrimary)
                        else
                          TextButton.icon(
                            onPressed: _resending ? null : _resend,
                            icon: _resending
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: textMuted,
                                    ),
                                  )
                                : Icon(Icons.refresh_rounded,
                                    size: 18, color: textMuted),
                            label: Text(
                              '¿No recibiste el correo? Reenviar',
                              style: AppTypography.bodySmall(color: textMuted),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
