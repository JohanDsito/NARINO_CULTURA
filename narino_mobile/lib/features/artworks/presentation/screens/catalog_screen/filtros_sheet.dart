import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/artwork_model.dart';
import '../../../domain/artwork_state.dart';
import '../../providers/artwork_provider.dart';

const _ordenes = <String, String>{
  'fecha': 'Más recientes',
  'relevancia': 'Más vistas',
  'precio_asc': 'Menor precio',
  'precio_desc': 'Mayor precio',
};

/// Panel de filtros: orden, categoría, técnica y rango de precio.
class FiltrosSheet extends ConsumerStatefulWidget {
  const FiltrosSheet({super.key, required this.state});

  final ArtworkState state;

  @override
  ConsumerState<FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends ConsumerState<FiltrosSheet> {
  String? _categoria;
  String? _tecnica;
  String _orden = 'fecha';
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  String? _precioError;

  @override
  void initState() {
    super.initState();
    _categoria = widget.state.categoriaFiltro;
    _tecnica = widget.state.tecnicaFiltro;
    _orden = widget.state.ordenarPor;
    if (widget.state.precioMinFiltro != null) {
      _minCtrl.text = widget.state.precioMinFiltro!.toStringAsFixed(0);
    }
    if (widget.state.precioMaxFiltro != null) {
      _maxCtrl.text = widget.state.precioMaxFiltro!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());

  void _apply() {
    final min = _num(_minCtrl);
    final max = _num(_maxCtrl);
    if (min != null && max != null && min > max) {
      setState(() => _precioError = 'El mínimo no puede ser mayor que el máximo');
      return;
    }
    ref.read(artworkProvider.notifier).aplicarFiltros(
          categoria: _categoria,
          tecnica: _tecnica,
          precioMin: min,
          precioMax: max,
          orden: _orden,
        );
    Navigator.pop(context);
  }

  void _clear() {
    ref.read(artworkProvider.notifier).limpiarFiltrosPanel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final categorias =
        ref.watch(categoriesProvider).valueOrNull ?? const <CategoryModel>[];

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 10),
          child: Text(title,
              style: AppTypography.labelSemiBold(color: nc.textPrimary)
                  .copyWith(fontSize: 14)),
        );

    Widget chip(String label, bool selected, NcAccent accent,
            VoidCallback onTap) =>
        ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => onTap(),
          selectedColor: accent.fill,
          backgroundColor: nc.itemFill,
          side: BorderSide(color: selected ? accent.fill : nc.border),
          labelStyle: AppTypography.labelMedium(
                  color: selected ? accent.onFill : nc.textPrimary)
              .copyWith(fontWeight: FontWeight.w600),
        );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: nc.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Filtros',
                      style:
                          AppTypography.displayBold(color: nc.textPrimary)),
                ),
                if (widget.state.filtrosPanelActivos > 0)
                  TextButton(onPressed: _clear, child: const Text('Limpiar')),
              ],
            ),
            const NcSerpentina(width: 48),

            section('Ordenar por'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in _ordenes.entries)
                  chip(e.value, _orden == e.key, nc.azulA,
                      () => setState(() => _orden = e.key)),
              ],
            ),

            section('Categoría'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                chip('Todas', _categoria == null, nc.catalogo,
                    () => setState(() => _categoria = null)),
                for (final c in categorias)
                  chip(c.displayName, _categoria == c.id.toString(), nc.catalogo,
                      () => setState(() => _categoria = c.id.toString())),
              ],
            ),

            section('Técnica'),
            DropdownButtonFormField<String?>(
              initialValue: _tecnica,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.brush_outlined),
              ),
              hint: const Text('Cualquier técnica'),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Cualquier técnica')),
                for (final t in kTecnicasNarino)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => _tecnica = v),
            ),

            section('Precio (COP)'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() => _precioError = null),
                    decoration: const InputDecoration(
                      labelText: 'Mínimo',
                      prefixText: r'$ ',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('—',
                      style: AppTypography.bodyMedium(color: nc.textMuted)),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() => _precioError = null),
                    decoration: const InputDecoration(
                      labelText: 'Máximo',
                      prefixText: r'$ ',
                    ),
                  ),
                ),
              ],
            ),
            if (_precioError != null) ...[
              const SizedBox(height: 8),
              Text(_precioError!,
                  style: AppTypography.bodySmall(color: nc.tomateA.ink)),
            ],
            const SizedBox(height: 28),
            NcPrimaryButton(label: 'Ver resultados', onPressed: _apply),
          ],
        ),
      ),
    );
  }
}
