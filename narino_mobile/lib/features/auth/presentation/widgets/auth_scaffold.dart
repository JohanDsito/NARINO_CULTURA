import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';

/// Estructura común de las pantallas de acceso (login, registro, recuperar,
/// verificar): fondo carnaval con parallax, logo con brillo y serpentina,
/// título grande y el contenido dentro de una tarjeta con borde neón.
class AuthScaffold extends ConsumerStatefulWidget {
  const AuthScaffold({
    super.key,
    required this.kicker,
    required this.title,
    this.subtitle,
    required this.child,
    this.footer,
    this.onBack,
    this.logoAccent,
  });

  /// Línea pequeña sobre el título (en oro).
  final String kicker;
  final String title;
  final String? subtitle;

  /// Contenido de la tarjeta (formulario o estado).
  final Widget child;

  /// Contenido bajo la tarjeta (enlaces a otras pantallas).
  final Widget? footer;

  /// Si no es `null`, muestra el botón "volver".
  final VoidCallback? onBack;

  /// Color del brillo del logo (por defecto magenta).
  final NcAccent? logoAccent;

  @override
  ConsumerState<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends ConsumerState<AuthScaffold> {
  final _offset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final brightness = Theme.of(context).brightness;
    final glow = widget.logoAccent ?? nc.magentaA;

    final title = Text(
      widget.title,
      textAlign: TextAlign.center,
      style: AppTypography.displayBlack(color: nc.textPrimary)
          .copyWith(fontSize: 30, height: 1.1),
    );

    final topBar = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          if (widget.onBack != null)
            NcIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Volver',
              onPressed: widget.onBack,
            ),
          const Spacer(),
          NcIconButton(
            icon: brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            tooltip: brightness == Brightness.dark
                ? 'Cambiar a modo claro'
                : 'Cambiar a modo oscuro',
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggle(brightness),
          ),
        ],
      ),
    );

    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Marca ──
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: nc.tintedShadow(glow.fill),
              ),
              child: const NcBrandMark(size: 60),
            ),
            const SizedBox(height: 14),
            const NcSerpentina(width: 72),
            const SizedBox(height: 22),
            Text(
              widget.kicker.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTypography.kicker(color: nc.oroA.ink),
            ),
            const SizedBox(height: 10),
            Semantics(
              header: true,
              child: nc.isDark
                  ? ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (r) => nc.titleGradient.createShader(r),
                      child: title,
                    )
                  : title,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(color: nc.textSecondary)
                    .copyWith(fontSize: 15),
              ),
            ],
            const SizedBox(height: 26),
            NcCard(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              child: widget.child,
            ),
            if (widget.footer != null) ...[
              const SizedBox(height: 20),
              widget.footer!,
            ],
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: nc.bg,
      body: Stack(
        children: [
          Positioned.fill(child: CarnavalBackground(scrollOffset: _offset)),
          SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.depth == 0) _offset.value = n.metrics.pixels;
                return false;
              },
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    children: [
                      topBar,
                      // Centra el contenido si cabe; si no, se desplaza.
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - 60)
                              .clamp(0, double.infinity)
                              .toDouble(),
                        ),
                        child: Center(child: content),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "¿No tienes cuenta? Regístrate" — texto + enlace con área táctil de 44 px.
class AuthLink extends StatelessWidget {
  const AuthLink({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onTap,
    this.enabled = true,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(question,
            style: AppTypography.bodyMedium(color: nc.textSecondary)),
        TextButton(
          onPressed: enabled ? onTap : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(44, 44),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

/// Título interno de la tarjeta.
class AuthCardTitle extends StatelessWidget {
  const AuthCardTitle(this.text, {super.key, this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: AppTypography.displaySemiBold(color: nc.textPrimary)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!,
              style: AppTypography.bodyMedium(color: nc.textSecondary)),
        ],
      ],
    );
  }
}
