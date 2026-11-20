import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

/// Descripción con "Ver más".
class DescriptionBlock extends StatefulWidget {
  const DescriptionBlock({super.key, required this.text});

  final String text;

  @override
  State<DescriptionBlock> createState() => _DescriptionBlockState();
}

class _DescriptionBlockState extends State<DescriptionBlock> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final largo = widget.text.length > 220;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sobre la obra',
            style: AppTypography.displaySemiBold(color: nc.textPrimary)),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topCenter,
          child: Text(
            widget.text,
            maxLines: _open || !largo ? null : 5,
            overflow: _open || !largo ? null : TextOverflow.ellipsis,
            style: AppTypography.bodyLarge(color: nc.textSecondary)
                .copyWith(fontSize: 15),
          ),
        ),
        if (largo)
          TextButton(
            onPressed: () => setState(() => _open = !_open),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(_open ? 'Ver menos' : 'Ver más'),
          ),
      ],
    );
  }
}
