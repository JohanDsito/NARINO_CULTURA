import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../widgets/disciplinas.dart';

/// Avatar editable con anillo de serpentina y vista previa del nombre.
class EditProfileHeader extends StatelessWidget {
  const EditProfileHeader({
    super.key,
    required this.nombre,
    required this.disciplina,
    required this.foto,
    required this.fotoUrl,
    required this.onFoto,
  });

  final TextEditingController nombre;
  final String? disciplina;
  final File? foto;
  final String? fotoUrl;
  final VoidCallback onFoto;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final d = disciplinaDe(disciplina);
    final accent = d?.accent(nc) ?? nc.catalogo;
    final texto = nombre.text.trim();
    final ImageProvider<Object>? img = foto != null
        ? FileImage(foto!) as ImageProvider<Object>
        : (fotoUrl != null && fotoUrl!.isNotEmpty
            ? CachedNetworkImageProvider(fotoUrl!)
            : null);

    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Cambiar foto de perfil',
          onTap: onFoto,
          excludeSemantics: true,
          child: NcPressable(
            onTap: onFoto,
            pressedScale: 0.95,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: [
                      ...nc.carnavalGradient.colors,
                      nc.carnavalGradient.colors.first,
                    ]),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: nc.bgCard,
                    backgroundImage: img,
                    child: img == null
                        ? Text(
                            texto.isEmpty
                                ? '?'
                                : texto.characters.first.toUpperCase(),
                            style: AppTypography.displayBold(color: accent.ink)
                                .copyWith(fontSize: 36))
                        : null,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: nc.azulA.fill,
                      shape: BoxShape.circle,
                      border: Border.all(color: nc.bg, width: 3),
                    ),
                    child: Icon(Icons.photo_camera_rounded,
                        size: 17, color: nc.azulA.onFill),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(texto.isEmpty ? 'Tu nombre' : texto,
            textAlign: TextAlign.center,
            style: AppTypography.displayBold(
                color: texto.isEmpty ? nc.textMuted : nc.textPrimary)),
        if (d != null || (disciplina ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          NcStatusPill(
              label: d?.label ?? disciplina!, accent: accent, filled: true),
        ],
      ],
    );
  }
}
