import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Avatar circular con fallback ante errores de red o imagen indecodificable.
/// Reemplaza CircleAvatar + NetworkImage para evitar FlutterJNI decode errors.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.radius,
    this.url,
    this.file,
    this.initials = '?',
    this.backgroundColor,
    this.initialsColor,
  });

  final double radius;
  final String? url;
  final File? file;
  final String initials;
  final Color? backgroundColor;
  final Color? initialsColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.tierraPalida;
    final fgColor = initialsColor ?? AppColors.tierraProfunda;
    final size = radius * 2;

    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials.isNotEmpty ? initials[0].toUpperCase() : '?',
        style: AppTypography.displayBold(color: fgColor)
            .copyWith(fontSize: radius * 0.72),
      ),
    );

    if (file != null) {
      return ClipOval(
        child: Image.file(
          file!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      );
    }

    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : placeholder,
        ),
      );
    }

    return placeholder;
  }
}
