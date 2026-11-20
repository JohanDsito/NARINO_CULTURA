import 'package:flutter/material.dart';

/// Una pestaña de la barra inferior.

class ShellTab {
  const ShellTab({
    required this.path,
    required this.label,
    required this.iconOutlined,
    required this.iconFilled,
  });

  final String path;
  final String label;
  final IconData iconOutlined;
  final IconData iconFilled;
}
