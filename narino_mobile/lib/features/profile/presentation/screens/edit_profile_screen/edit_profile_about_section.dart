import 'package:flutter/material.dart';

import 'edit_profile_section.dart';

/// "Sobre ti": nombre y, para artistas, municipio y biografía.
class EditProfileAboutSection extends StatelessWidget {
  const EditProfileAboutSection({
    super.key,
    required this.nombre,
    required this.ciudad,
    required this.bio,
    required this.esArtista,
    required this.onNombreChanged,
  });

  final TextEditingController nombre;
  final TextEditingController ciudad;
  final TextEditingController bio;
  final bool esArtista;

  /// Para refrescar la vista previa de la cabecera.
  final VoidCallback onNombreChanged;

  @override
  Widget build(BuildContext context) {
    return EditProfileSection(
      titulo: 'Sobre ti',
      children: [
        TextFormField(
          controller: nombre,
          textCapitalization: TextCapitalization.words,
          maxLength: 120,
          onChanged: (_) => onNombreChanged(),
          decoration: InputDecoration(
            labelText: esArtista ? 'Nombre artístico' : 'Nombre',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            counterText: '',
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Escribe cómo quieres que te vean'
              : null,
        ),
        if (esArtista) ...[
          const SizedBox(height: 14),
          TextFormField(
            controller: ciudad,
            textCapitalization: TextCapitalization.words,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Municipio (opcional)',
              hintText: 'Ej.: Pasto, Ipiales, Tumaco',
              prefixIcon: Icon(Icons.place_outlined),
              counterText: '',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: bio,
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Biografía (opcional)',
              hintText: 'Tu historia, tu técnica, lo que te inspira…',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ],
    );
  }
}
