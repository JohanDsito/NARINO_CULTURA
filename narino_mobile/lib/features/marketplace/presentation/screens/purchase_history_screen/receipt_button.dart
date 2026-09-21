import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Botón de comprobante ─────────────────────────────────────────────────────

class ReceiptButton extends StatelessWidget {
  const ReceiptButton({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
      label: const Text('Comprobante'),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 32),
      ),
    );
  }
}
