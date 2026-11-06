import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../artworks/presentation/providers/artwork_provider.dart';

class _Disciplina {
  const _Disciplina(this.emoji, this.title, this.text, this.link, this.action);
  final String emoji;
  final String title;
  final String text;
  final String link;
  final Future<void> Function(BuildContext, WidgetRef) action;
}

Future<void> _irCatalogo(BuildContext context, WidgetRef ref,
    {String? categoriaContiene}) async {
  final notifier = ref.read(artworkProvider.notifier);
  if (categoriaContiene == null) {
    notifier.setCategoria(null);
  } else {
    try {
      final cats = await ref.read(categoriesProvider.future);
      final match = cats.where(
          (c) => c.name.toLowerCase().contains(categoriaContiene)).firstOrNull;
      notifier.setCategoria(match?.id.toString());
    } catch (_) {
      notifier.setCategoria(null);
    }
  }
  if (context.mounted) context.go('/catalog');
}

final _disciplinas = <_Disciplina>[
  _Disciplina(
    '🎨',
    'Artesanos & Plásticos',
    'Obras originales, tejido guaneña, barniz de Pasto y carrozas a escala. '
        'Adquiere arte directamente del creador.',
    'Ver galería →',
    (c, r) => _irCatalogo(c, r),
  ),
  _Disciplina(
    '🎸',
    'Músicos & Sonido',
    'Descubre ensambles, escucha sus obras y sigue la música que mueve '
        'nuestro departamento.',
    'Explorar sonidos →',
    (c, r) async => c.push('/musicians'),
  ),
  _Disciplina(
    '📸',
    'Fotógrafos',
    'El registro gráfico del Carnaval y nuestros paisajes. Compra '
        'impresiones de alta calidad directamente al fotógrafo.',
    'Ver portafolios →',
    (c, r) => _irCatalogo(c, r, categoriaContiene: 'foto'),
  ),
  _Disciplina(
    '🔨',
    'Subastas en vivo',
    'Puja en tiempo real por piezas únicas de creadores nariñenses y sigue '
        'cada oferta al instante.',
    'Ver subastas →',
    (c, r) async => c.go('/auctions'),
  ),
];

/// Carrusel horizontal de disciplinas con indicadores (`.carousel` + `.dots`).
class DisciplinesCarousel extends ConsumerStatefulWidget {
  const DisciplinesCarousel({super.key});

  @override
  ConsumerState<DisciplinesCarousel> createState() =>
      _DisciplinesCarouselState();
}

class _DisciplinesCarouselState extends ConsumerState<DisciplinesCarousel> {
  final _controller = PageController(viewportFraction: 0.82);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const NcSectionHeader(title: 'Disciplinas'),
        const SizedBox(height: 16),
        SizedBox(
          height: 300 * textScale.clamp(1.0, 1.6),
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: _disciplinas.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final d = _disciplinas[i];
              return Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 20 : 7,
                  right: i == _disciplinas.length - 1 ? 20 : 7,
                  top: 6,
                  bottom: 14,
                ),
                child: NcCard(
                  onTap: () => d.action(context, ref),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Text(d.emoji,
                            style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        d.title,
                        style: AppTypography.displaySemiBold(
                            color: nc.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Text(
                          d.text,
                          overflow: TextOverflow.fade,
                          style: AppTypography.bodyMedium(
                              color: nc.textSecondary),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            d.link,
                            style: AppTypography.labelSemiBold(color: nc.azul)
                                .copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _disciplinas.length; i++)
              AnimatedContainer(
                duration:
                    reduce ? Duration.zero : const Duration(milliseconds: 400),
                curve: kNcEase,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _page ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: i == _page
                      ? nc.azul
                      : nc.textSecondary.withValues(alpha: 0.35),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
