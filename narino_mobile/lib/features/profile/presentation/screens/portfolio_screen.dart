import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/profile_provider.dart';
import '../../domain/portfolio_item_model.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  final _picker = ImagePicker();

  Future<void> _addItem() async {
    final state = ref.read(myProfileProvider);
    if (state.portfolio.length >= 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 30 elementos en el portafolio.')),
      );
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Agregar imagen'),
              onTap: () => Navigator.pop(context, 'imagen'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Agregar video'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    File? file;
    if (choice == 'imagen') {
      final picked = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) file = File(picked.path);
    } else {
      final picked = await _picker.pickVideo(source: ImageSource.gallery);
      if (picked != null) file = File(picked.path);
    }

    if (file == null) return;

    final sizeBytes = await file.length();
    if (sizeBytes > 50 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El archivo supera los 50 MB permitidos.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    await ref.read(myProfileProvider.notifier).addPortfolioItem(
          file: file,
          tipo: choice,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(
          'Mi portafolio (${state.portfolio.length}/30)',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro)
              .copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.add_circle_outline, color: AppColors.oroClaro),
            onPressed: _addItem,
          ),
        ],
      ),
      body: state.portfolio.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.collections_outlined,
                    color: AppColors.textMutedLight,
                    size: 72,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tu portafolio está vacío',
                    style: AppTypography.displaySemiBold(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Agrega imágenes y videos de tu trabajo',
                    style: AppTypography.bodySmall(
                        color: AppColors.textMutedLight),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar elemento'),
                    onPressed: _addItem,
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: state.portfolio.length,
              itemBuilder: (_, i) => _buildPortfolioItem(state.portfolio[i]),
            ),
    );
  }

  Widget _buildPortfolioItem(PortfolioItemModel item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.isImage
              ? Image.network(
                  item.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.bgSubtleLight,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textMutedLight,
                    ),
                  ),
                )
              : Container(
                  color: AppColors.obsidiana,
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: AppColors.oroClaro,
                      size: 40,
                    ),
                  ),
                ),
        ),
        Positioned(
          top: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              item.isVideo ? Icons.videocam : Icons.image,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () async {
              final ok = await ref
                  .read(myProfileProvider.notifier)
                  .deletePortfolioItem(item.id);
              if (!ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al eliminar')),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}
