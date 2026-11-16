import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class PortadaObra extends StatelessWidget {
  const PortadaObra({
    super.key,
    required this.archivo,
    required this.urlActual,
    required this.error,
    required this.onTap,
  });

  final XFile? archivo;
  final String? urlActual;
  final bool error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final tieneImagen = archivo != null || urlActual != null;

    Widget contenido;
    if (archivo != null) {
      contenido = Image.file(File(archivo!.path), fit: BoxFit.cover);
    } else if (urlActual != null) {
      contenido = CachedNetworkImage(imageUrl: urlActual!, fit: BoxFit.cover);
    } else {
      contenido = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NcAccentIcon(
            icon: Icons.add_photo_alternate_outlined,
            accent: error ? nc.tomateA : nc.catalogo,
            size: 56,
          ),
          const SizedBox(height: 12),
          Text('Toca para agregar la portada',
              style: AppTypography.labelSemiBold(
                  color: error ? nc.tomateA.ink : nc.textPrimary)),
          const SizedBox(height: 2),
          Text('JPG o PNG · se ajusta automáticamente',
              style: AppTypography.bodySmall(color: nc.textSecondary)),
        ],
      );
    }

    return Semantics(
      button: true,
      label: tieneImagen
          ? 'Cambiar imagen de portada'
          : 'Agregar imagen de portada',
      onTap: onTap,
      excludeSemantics: true,
      child: NcPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            decoration: BoxDecoration(
              color: tieneImagen ? Colors.black : nc.catalogo.tint,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: error
                    ? nc.tomateA.fill
                    : (tieneImagen
                        ? nc.border
                        : nc.catalogo.fill.withValues(alpha: 0.5)),
                width: error ? 1.6 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                contenido,
                if (tieneImagen && onTap != null)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          color: Colors.black.withValues(alpha: 0.4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_outlined,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text('Cambiar',
                                  style: AppTypography.labelMedium(
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
