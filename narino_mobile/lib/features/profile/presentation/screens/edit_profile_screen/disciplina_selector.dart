import 'package:flutter/material.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../widgets/disciplinas.dart';
import 'edit_profile_chip.dart';

/// Disciplinas conocidas con su color. Si la guardada es otra (texto libre de
/// la web o el admin), se conserva como una opción más.
class DisciplinaSelector extends StatelessWidget {
  const DisciplinaSelector(
      {super.key, required this.valor, required this.onChanged});

  final String? valor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final actual = disciplinaDe(valor);
    final otra = valor != null && valor!.trim().isNotEmpty && actual == null;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final d in kDisciplinas)
          EditProfileChip(
            label: d.label,
            icon: d.icon,
            accent: d.accent(nc),
            selected: actual?.value == d.value,
            // Se guarda el valor canónico (el mismo que usa la web).
            onTap: () => onChanged(d.value),
          ),
        if (otra)
          EditProfileChip(
            label: valor!,
            icon: Icons.auto_awesome_outlined,
            accent: nc.successA,
            selected: true,
            onTap: () {},
          ),
      ],
    );
  }
}
