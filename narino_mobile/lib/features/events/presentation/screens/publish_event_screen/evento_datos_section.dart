import 'package:flutter/material.dart';

import '../../../../../shared/widgets/design/design.dart';

/// "Cuéntanos del evento": nombre, lugar y descripción.
class EventoDatosSection extends StatelessWidget {
  const EventoDatosSection({
    super.key,
    required this.nombre,
    required this.lugar,
    required this.descripcion,
  });

  final TextEditingController nombre;
  final TextEditingController lugar;
  final TextEditingController descripcion;

  @override
  Widget build(BuildContext context) {
    return NcFormSection(
      title: 'Cuéntanos del evento',
      children: [
        TextFormField(
          controller: nombre,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 120,
          decoration: const InputDecoration(
              labelText: 'Nombre del evento', counterText: ''),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Ponle un nombre al evento'
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: lugar,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Lugar',
            hintText: 'Ej.: Teatro Imperial, Pasto',
            prefixIcon: Icon(Icons.place_outlined),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Indica dónde será' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: descripcion,
          minLines: 3,
          maxLines: 6,
          maxLength: 1500,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Descripción (opcional)',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
