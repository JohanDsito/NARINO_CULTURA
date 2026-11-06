import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../artworks/domain/artwork_model.dart';
import '../providers/auctions_provider.dart';
import '../widgets/subasta_ui.dart';

const _duraciones = [1, 3, 7, 14, 30];
const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String _fecha(DateTime d) =>
    '${d.day} ${_meses[d.month - 1]} · ${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}';

/// Abrir una subasta con una obra disponible (acento oro).
class CreateAuctionScreen extends ConsumerStatefulWidget {
  const CreateAuctionScreen({super.key});

  @override
  ConsumerState<CreateAuctionScreen> createState() =>
      _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends ConsumerState<CreateAuctionScreen> {
  final _precioCtrl = TextEditingController();
  ArtworkModel? _obra;
  int _dias = 7;
  late DateTime _inicio = _manana18();
  bool _isSubmitting = false;
  String? _error;

  static DateTime _manana18() {
    final n = DateTime.now().add(const Duration(days: 1));
    return DateTime(n.year, n.month, n.day, 18);
  }

  @override
  void dispose() {
    _precioCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirInicio() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _inicio.isBefore(now) ? now : _inicio,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_inicio),
    );
    if (!mounted) return;
    setState(() => _inicio = DateTime(date.year, date.month, date.day,
        time?.hour ?? _inicio.hour, time?.minute ?? _inicio.minute));
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final precio = double.tryParse(_precioCtrl.text.trim()) ?? 0;
    final faltan = <String>[
      if (_obra == null) 'elige una obra',
      if (precio <= 0) 'escribe un precio base',
    ];
    if (faltan.isNotEmpty) {
      setState(() => _error = 'Para continuar, ${faltan.join(' y ')}.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final auction = await ref.read(auctionsRepositoryProvider).createAuction(
            obraId: _obra!.id,
            precioBase: precio,
            duracionDias: _dias,
            fechaInicio: _inicio,
          );
      if (!mounted) return;
      // El backend deja la subasta PENDIENTE hasta que un admin la apruebe.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Subasta enviada. Saldrá en vivo cuando un '
            'administrador la apruebe.'),
      ));
      context.go('/auctions/${auction.id}');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final obrasAsync = ref.watch(myArtworksForAuctionProvider);
    final fin = _inicio.add(Duration(days: _dias));

    Widget titulo(String t, {String? hint}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t,
                  style: AppTypography.labelSemiBold(color: nc.textPrimary)),
              if (hint != null)
                Text(hint,
                    style: AppTypography.bodySmall(color: nc.textSecondary)),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Abrir subasta'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          // ── Obra ──
          NcCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titulo('¿Qué obra vas a subastar?',
                    hint: 'Solo aparecen tus obras disponibles.'),
                obrasAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => NcBanner.error(context, e.toString()),
                  data: (list) {
                    if (list.isEmpty) {
                      return NcBanner(
                        accent: nc.oroA,
                        message: 'No tienes obras disponibles para subastar. '
                            'Publica una primero desde "Mis obras".',
                      );
                    }
                    return SizedBox(
                      height: 176,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => _ObraOpcion(
                          obra: list[i],
                          selected: _obra?.id == list[i].id,
                          onTap: () => setState(() {
                            _obra = list[i];
                            if (_precioCtrl.text.isEmpty &&
                                list[i].precio != null) {
                              _precioCtrl.text =
                                  list[i].precio!.toStringAsFixed(0);
                            }
                          }),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Precio ──
          NcCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titulo('Precio base',
                    hint: 'Las pujas empiezan desde aquí. Puedes usar el '
                        'precio de la obra como referencia.'),
                TextField(
                  controller: _precioCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Precio base',
                    prefixText: r'$ ',
                    suffixText: 'COP',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Tiempo ──
          NcCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titulo('¿Cuándo y por cuánto tiempo?'),
                OutlinedButton.icon(
                  onPressed: _elegirInicio,
                  icon: const Icon(Icons.event_rounded),
                  label: Text('Empieza: ${_fecha(_inicio)}'),
                ),
                const SizedBox(height: 14),
                Text('Duración',
                    style: AppTypography.labelMedium(color: nc.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in _duraciones)
                      ChoiceChip(
                        label: Text(d == 1 ? '1 día' : '$d días'),
                        selected: _dias == d,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _dias = d),
                        selectedColor: nc.subastas.fill,
                        side: BorderSide(
                            color: _dias == d ? nc.subastas.fill : nc.border),
                        labelStyle: AppTypography.labelMedium(
                          color: _dias == d
                              ? nc.subastas.onFill
                              : nc.textPrimary,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 18, color: nc.subastas.ink),
                    const SizedBox(width: 8),
                    Text('Termina: ${_fecha(fin)}',
                        style: AppTypography.labelSemiBold(
                                color: nc.subastas.ink)
                            .copyWith(fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NcBanner(
            accent: nc.azulA,
            icon: Icons.verified_outlined,
            message: 'Un administrador revisa cada subasta antes de publicarla. '
                'Te avisaremos cuando salga en vivo.',
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            NcBanner.error(context, _error!),
          ],
        ],
      ),
      bottomNavigationBar: NcGlassBottomBar(
        child: NcPrimaryButton(
          label: 'Enviar a revisión',
          icon: Icons.gavel_rounded,
          loading: _isSubmitting,
          onPressed: _submit,
        ),
      ),
    );
  }
}

class _ObraOpcion extends StatelessWidget {
  const _ObraOpcion({
    required this.obra,
    required this.selected,
    required this.onTap,
  });

  final ArtworkModel obra;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final img = obra.imagenes.isNotEmpty ? obra.imagenes.first : null;
    return Semantics(
      selected: selected,
      button: true,
      label: obra.titulo,
      excludeSemantics: true,
      child: NcPressable(
        onTap: onTap,
        pressedScale: 0.96,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 132,
          decoration: BoxDecoration(
            color: nc.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? nc.subastas.fill : nc.border,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    img == null
                        ? const SubastaImage(url: null)
                        : CachedNetworkImage(imageUrl: img, fit: BoxFit.cover),
                    if (selected)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              color: nc.subastas.fill,
                              shape: BoxShape.circle),
                          child: Icon(Icons.check_rounded,
                              size: 16, color: nc.subastas.onFill),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(obra.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium(color: nc.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
