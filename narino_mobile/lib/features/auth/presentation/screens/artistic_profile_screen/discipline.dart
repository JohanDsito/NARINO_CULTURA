import 'package:flutter/material.dart';

/// Datos de una disciplina artística disponible para seleccionar.
class Discipline {
  const Discipline({
    required this.label,
    required this.value,
    required this.icon,
    required this.description,
  });

  final String label;
  final String value;
  final IconData icon;
  final String description;
}
