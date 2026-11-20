import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/nc_theme.dart';
import 'nc_header.dart';
import 'nc_month_calendar/nc_day_cell.dart';

const kMesesNombre = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];
const _diasCortos = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

/// Solo la fecha (sin hora), para comparar días.
DateTime soloDia(DateTime d) => DateTime(d.year, d.month, d.day);

/// Calendario mensual del design system (`.calendar-grid`): día elegido en
/// azul neón con brillo y punto naranja en los días con eventos.
class NcMonthCalendar extends StatelessWidget {
  const NcMonthCalendar({
    super.key,
    required this.view,
    required this.selected,
    required this.markedDays,
    required this.onPrev,
    required this.onNext,
    required this.onSelect,
  });

  /// Cualquier fecha del mes visible.
  final DateTime view;
  final DateTime selected;
  final Set<DateTime> markedDays;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final first = DateTime(view.year, view.month, 1);
    final total = DateTime(view.year, view.month + 1, 0).day;
    final prevTotal = DateTime(view.year, view.month, 0).day;
    final leading = first.weekday % 7; // domingo = 0
    final hoy = soloDia(DateTime.now());
    final sel = soloDia(selected);

    final cells = <Widget>[
      for (var i = leading - 1; i >= 0; i--)
        NcDayCell(label: '${prevTotal - i}', muted: true),
      for (var d = 1; d <= total; d++)
        () {
          final date = DateTime(view.year, view.month, d);
          final marcado = markedDays.contains(date);
          return NcDayCell(
            label: '$d',
            active: date == sel,
            today: date == hoy,
            hasEvent: marcado,
            semantics: '$d de ${kMesesNombre[view.month - 1].toLowerCase()}'
                '${date == hoy ? ', hoy' : ''}${marcado ? ', con eventos' : ''}',
            onTap: () => onSelect(date),
          );
        }(),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${kMesesNombre[view.month - 1]} ${view.year}',
                style: AppTypography.labelSemiBold(color: nc.textPrimary)
                    .copyWith(fontSize: 17),
              ),
            ),
            NcIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Mes anterior',
              bordered: false,
              size: 40,
              onPressed: onPrev,
            ),
            const SizedBox(width: 4),
            NcIconButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Mes siguiente',
              bordered: false,
              size: 40,
              onPressed: onNext,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final d in _diasCortos)
              Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption(color: nc.textSecondary)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
      ],
    );
  }
}
