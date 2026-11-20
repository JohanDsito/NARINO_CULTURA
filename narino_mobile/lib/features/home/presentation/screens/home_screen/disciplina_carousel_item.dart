import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DisciplinaCarouselItem {
  const DisciplinaCarouselItem(
      this.emoji, this.title, this.text, this.link, this.action);
  final String emoji;
  final String title;
  final String text;
  final String link;
  final Future<void> Function(BuildContext, WidgetRef) action;
}
