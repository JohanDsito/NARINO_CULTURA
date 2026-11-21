import '../../../../../core/theme/nc_theme.dart';

NcAccent estadoOrdenAccent(NcColors nc, String estado) => switch (estado) {
      'completado' => nc.successA,
      'pendiente' => nc.oroA,
      'fallido' => nc.tomateA,
      _ => nc.azulA,
    };
