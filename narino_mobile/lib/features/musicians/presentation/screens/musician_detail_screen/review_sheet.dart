import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/musician_model.dart';
import '../../providers/musician_provider.dart';

class ReviewSheet extends ConsumerStatefulWidget {
  const ReviewSheet({super.key, required this.musician});

  final MusicianModel musician;

  @override
  ConsumerState<ReviewSheet> createState() => _ResenaSheetState();
}

class _ResenaSheetState extends ConsumerState<ReviewSheet> {
  int _rating = 0;
  final _ctrl = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_rating == 0) {
      setState(() => _error = 'Elige de 1 a 5 estrellas.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ref
          .read(musicianRepositoryProvider)
          .addReview(widget.musician.slug, _rating, _ctrl.text);
      ref.invalidate(musicianReviewsProvider(widget.musician.slug));
      ref.invalidate(musicianDetailProvider(widget.musician.slug));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Gracias por tu reseña!')));
    } catch (e) {
      if (mounted) {
        setState(() {
          _enviando = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Reseña para ${widget.musician.name}',
                style: AppTypography.displaySemiBold(color: nc.textPrimary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i estrella${i == 1 ? '' : 's'}',
                    iconSize: 40,
                    onPressed: () => setState(() => _rating = i),
                    icon: Icon(
                      _rating >= i
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: nc.oro,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              minLines: 3,
              maxLines: 6,
              maxLength: 600,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Cuéntanos tu experiencia (opcional)',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              NcBanner.error(context, _error!),
            ],
            const SizedBox(height: 16),
            NcPrimaryButton(
              label: 'Publicar reseña',
              loading: _enviando,
              onPressed: _enviar,
            ),
          ],
        ),
      ),
    );
  }
}
