import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../core/theme/nc_theme.dart';

class MyArtworkMenu extends StatelessWidget {
  const MyArtworkMenu({
    super.key,
    required this.disponible,
    required this.onEdit,
    required this.onAuction,
    required this.onDelete,
  });

  final bool disponible;
  final VoidCallback onEdit;
  final VoidCallback onAuction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.black.withValues(alpha: 0.35),
          shape: const CircleBorder(),
          child: PopupMenuButton<String>(
            tooltip: 'Opciones de la obra',
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
            onSelected: (v) => switch (v) {
              'edit' => onEdit(),
              'auction' => onAuction(),
              'delete' => onDelete(),
              _ => null,
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar'),
                ),
              ),
              if (disponible)
                PopupMenuItem(
                  value: 'auction',
                  child: ListTile(
                    leading: Icon(Icons.gavel_rounded, color: nc.subastas.ink),
                    title: const Text('Subastar'),
                  ),
                ),
              if (disponible)
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline_rounded,
                        color: nc.tomateA.ink),
                    title: Text('Eliminar',
                        style: TextStyle(color: nc.tomateA.ink)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
