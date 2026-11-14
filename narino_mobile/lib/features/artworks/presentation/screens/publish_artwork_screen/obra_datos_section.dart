import 'package:flutter/material.dart';

import '../../../../../shared/widgets/design/design.dart';

/// "Sobre la obra": título, descripción y botón de IA.
class ObraDatosSection extends StatelessWidget {
  const ObraDatosSection({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.editable,
    required this.iaDisponible,
    required this.generando,
    required this.onGenerar,
  });

  final TextEditingController titulo;
  final TextEditingController descripcion;
  final bool editable;
  final bool iaDisponible;
  final bool generando;
  final VoidCallback onGenerar;

  @override
  Widget build(BuildContext context) {
    return NcFormSection(
      title: 'Sobre la obra',
      children: [
        TextFormField(
          controller: titulo,
          enabled: editable,
          maxLength: 120,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Título',
            counterText: '',
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Ponle un título a tu obra'
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: descripcion,
          enabled: editable,
          minLines: 4,
          maxLines: 8,
          maxLength: 1500,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            alignLabelWithHint: true,
            hintText: 'Cuenta la historia, la técnica y qué la hace especial.',
          ),
        ),
        if (iaDisponible)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: generando ? null : onGenerar,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Escribir con IA'),
            ),
          ),
      ],
    );
  }
}
