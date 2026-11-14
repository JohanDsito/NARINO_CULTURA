import 'package:flutter/material.dart';
import '../../../../../core/theme/nc_theme.dart';

class CatalogSearchField extends StatelessWidget {
  const CatalogSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(99),
      borderSide: BorderSide(color: nc.border),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar obras, técnicas o artistas',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Borrar búsqueda',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              ),
        fillColor: nc.bgGlass,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: pill,
        enabledBorder: pill,
        focusedBorder: pill.copyWith(
          borderSide: BorderSide(color: nc.catalogo.fill, width: 1.5),
        ),
      ),
    );
  }
}
