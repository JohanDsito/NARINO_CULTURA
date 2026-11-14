/// Tipos de agrupación musical. Clave: valor del backend
/// (`aggregation_type`). Valor: etiqueta visible.
const kAgrupaciones = <String, String>{
  'SOLISTA': 'Solista',
  'DUO': 'Dúo',
  'TRIO': 'Trío',
  'BANDA': 'Banda',
  'COLECTIVO': 'Colectivo',
  'DJ': 'DJ',
};

/// Etiqueta de una agrupación (`'BANDA'` → `'Banda'`); vacía si no se conoce.
String formatoAgrupacion(String? tipo) =>
    kAgrupaciones[tipo?.toUpperCase()] ?? '';
