import 'package:flutter/material.dart';

import 'artwork_card_shell.dart';

class ArtworkCardMock extends StatelessWidget {
  const ArtworkCardMock({required this.data, super.key});

  final Map<String, String> data;

  @override
  Widget build(BuildContext context) {
    return ArtworkCardShell(
      title: data['title']!,
      artist: data['artist']!,
      price: data['price']!,
      onTap: null,
    );
  }
}
