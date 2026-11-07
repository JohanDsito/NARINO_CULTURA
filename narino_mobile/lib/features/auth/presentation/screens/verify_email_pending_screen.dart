import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';

class VerifyEmailPendingScreen extends ConsumerStatefulWidget {
  const VerifyEmailPendingScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailPendingScreen> createState() =>
      _VerifyEmailPendingScreenState();
}

class _VerifyEmailPendingScreenState
    extends ConsumerState<VerifyEmailPendingScreen> {
  bool _resending = false;

  /// `true` = reenviado; `false` = falló; `null` = aún no se intenta.
  bool? _resent;

  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resendVerification(email: widget.email);
      if (mounted) setState(() => _resent = true);
    } catch (_) {
      // El backend aún no expone el reenvío: se avisa en vez de fallar en
      // silencio.
      if (mounted) setState(() => _resent = false);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final steps = <(String, NcAccent)>[
      ('Abre tu aplicación de correo.', nc.tomateA),
      (
        'Busca el mensaje de Nariño Cultura y toca "Verificar mi cuenta".',
        nc.naranjaA
      ),
      ('Vuelve aquí e inicia sesión con tu correo y contraseña.', nc.oroA),
    ];

    return AuthScaffold(
      kicker: 'Un paso más',
      title: '¡Cuenta creada!',
      subtitle: 'Solo falta confirmar que el correo es tuyo.',
      logoAccent: nc.successA,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: NcAccentIcon(
              icon: Icons.mark_email_unread_outlined,
              accent: nc.oroA,
              size: 72,
              glow: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Te enviamos un enlace de verificación a',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(color: nc.textSecondary),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: nc.secondaryFill,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: nc.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alternate_email_rounded,
                      size: 16, color: nc.textSecondary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.email,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSemiBold(color: nc.textPrimary)
                          .copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _Step(number: i + 1, text: steps[i].$1, accent: steps[i].$2),
          ],
          const SizedBox(height: 24),
          NcPrimaryButton(
            label: 'Ir a iniciar sesión',
            icon: Icons.login_rounded,
            onPressed: () => context.go('/login'),
          ),
          const SizedBox(height: 12),
          if (_resent == true)
            NcBanner.success(
                context, 'Correo reenviado. Revisa tu bandeja de entrada.')
          else if (_resent == false)
            NcBanner(
              accent: nc.oroA,
              message: 'Por ahora no podemos reenviar el correo desde la app. '
                  'Espera unos minutos y revisa spam o promociones.',
            )
          else
            Center(
              child: TextButton.icon(
                onPressed: _resending ? null : _resend,
                icon: _resending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('¿No te llegó? Reenviar'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text, required this.accent});

  final int number;
  final String text;
  final NcAccent accent;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: accent.fill, shape: BoxShape.circle),
          child: Text(
            '$number',
            style: AppTypography.labelSemiBold(color: accent.onFill)
                .copyWith(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text,
                style: AppTypography.bodyMedium(color: nc.textPrimary)),
          ),
        ),
      ],
    );
  }
}
