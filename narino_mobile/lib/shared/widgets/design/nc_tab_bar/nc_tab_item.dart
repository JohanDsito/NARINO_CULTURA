import 'package:flutter/material.dart';

class NcTabItem {
  const NcTabItem({required this.label, required this.icon, this.activeIcon});
  final String label;
  final IconData icon;
  final IconData? activeIcon;
}
