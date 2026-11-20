import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import 'disciplina_selector.dart';
import 'edit_profile_section.dart';

/// "Tu disciplina": selector con aviso si falta elegirla.
class EditProfileDisciplineSection extends StatelessWidget {
  const EditProfileDisciplineSection({
    super.key,
    required this.valor,
    required this.falta,
    required this.onChanged,
  });

  final String? valor;
  final bool falta;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return EditProfileSection(
      titulo: 'Tu disciplina',
      children: [
        DisciplinaSelector(valor: valor, onChanged: onChanged),
        if (falta) ...[
          const SizedBox(height: 8),
          Text('Elige tu disciplina',
              style: AppTypography.bodySmall(color: nc.tomateA.ink)),
        ],
      ],
    );
  }
}
