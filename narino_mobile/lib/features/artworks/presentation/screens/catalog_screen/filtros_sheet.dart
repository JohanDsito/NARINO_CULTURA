import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/artwork_model.dart';
import '../../../domain/artwork_state.dart';
import '../../providers/artwork_provider.dart';
import 'filter_label.dart';

// ─── Sheet de filtros ─────────────────────────────────────────────────────────

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
  final _precioMinCtrl = TextEditingController();
  final _precioMaxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categoria = widget.state.categoriaFiltro;
    _tecnica = widget.state.tecnicaFiltro;
    _orden = widget.state.ordenarPor;
    if (widget.state.precioMinFiltro != null) {
      _precioMinCtrl.text = widget.state.precioMinFiltro!.toStringAsFixed(0);
    }
    if (widget.state.precioMaxFiltro != null) {
      _precioMaxCtrl.text = widget.state.precioMaxFiltro!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _precioMinCtrl.dispose();
    _precioMaxCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final notifier = ref.read(artworkProvider.notifier);
    notifier.setCategoria(_categoria);
    notifier.setTecnica(_tecnica);
    notifier.setOrden(_orden);
    notifier.setRangoPrecio(
      _precioMinCtrl.text.trim().isNotEmpty
          ? double.tryParse(_precioMinCtrl.text.trim())
          : null,
      _precioMaxCtrl.text.trim().isNotEmpty
          ? double.tryParse(_precioMaxCtrl.text.trim())
          : null,
    );
    Navigator.pop(context);
  }

  void _clearFilters() {
    ref.read(artworkProvider.notifier).limpiarFiltros();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    // ✅ FIX: color de las etiquetas de sección resuelto desde el tema
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtros',
                  style: AppTypography.displaySemiBold(color: textPrimary),
                ),
                if (widget.state.hayFiltrosActivos)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                    label: const Text('Limpiar todo'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // ✅ FIX: FilterLabel ahora recibe el color resuelto desde el tema
            FilterLabel('Categoría', color: textSecondary),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _categoria,
              dropdownColor: theme.cardTheme.color ?? cs.surface,
              style: AppTypography.bodyMedium(color: textPrimary),
              hint: Text('Todas',
                  style: AppTypography.bodyMedium(color: textMuted)),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...kCategoriasNarino
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: (v) => setState(() => _categoria = v),
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),
            FilterLabel('Técnica', color: textSecondary),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _tecnica,
              dropdownColor: theme.cardTheme.color ?? cs.surface,
              style: AppTypography.bodyMedium(color: textPrimary),
              hint: Text('Todas',
                  style: AppTypography.bodyMedium(color: textMuted)),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...kTecnicasNarino
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))),
              ],
              onChanged: (v) => setState(() => _tecnica = v),
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),
            FilterLabel('Rango de precio (COP)', color: textSecondary),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _precioMinCtrl,
                    keyboardType: TextInputType.number,
                    style: AppTypography.bodyMedium(color: textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Mínimo',
                      prefixText: r'$',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _precioMaxCtrl,
                    keyboardType: TextInputType.number,
                    style: AppTypography.bodyMedium(color: textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Máximo',
                      prefixText: r'$',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilterLabel('Ordenar por', color: textSecondary),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _orden,
              dropdownColor: theme.cardTheme.color ?? cs.surface,
              style: AppTypography.bodyMedium(color: textPrimary),
              items: const [
                DropdownMenuItem(value: 'fecha', child: Text('Más recientes')),
                DropdownMenuItem(
                    value: 'precio_asc', child: Text('Precio: menor a mayor')),
                DropdownMenuItem(
                    value: 'precio_desc', child: Text('Precio: mayor a menor')),
                DropdownMenuItem(
                    value: 'relevancia', child: Text('Más populares')),
              ],
              onChanged: (v) => setState(() => _orden = v ?? 'fecha'),
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    // ✅ FIX: color del OutlinedButton resuelto desde el tema
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary),
                    ),
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    // ✅ FIX: colores del ElevatedButton resueltos desde el tema
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    child: const Text('Aplicar filtros'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
