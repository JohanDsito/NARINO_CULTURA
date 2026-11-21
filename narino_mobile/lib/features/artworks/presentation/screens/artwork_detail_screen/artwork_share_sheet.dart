import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../domain/artwork_model.dart';
import 'share_option.dart';

// ─── Share sheet ──────────────────────────────────────────────────────────────

/// Hoja para compartir una obra: WhatsApp, Facebook, X o el menú del sistema.
Future<void> mostrarCompartirObra(
    BuildContext context, ArtworkModel artwork) async {
  final url = 'https://narinocultura.app/artworks/${artwork.id}';
  final texto =
      '🎨 ${artwork.titulo} — por ${artwork.artistaNombre}\n\nDescubre esta obra en Nariño Cultura:\n$url';

  final nc = context.nc;
  final bgCard = nc.bgCard;
  final handleColor = nc.border;
  final titleColor = nc.textPrimary;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Compartir obra',
            style: AppTypography.displaySemiBold(color: titleColor),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ShareOption(
                icon: Icons.chat_bubble_outline,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () {
                  _shareToWhatsApp(texto);
                  Navigator.pop(context);
                },
              ),
              ShareOption(
                icon: Icons.facebook_outlined,
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                onTap: () {
                  _shareToFacebook(url);
                  Navigator.pop(context);
                },
              ),
              ShareOption(
                icon: Icons.alternate_email,
                label: 'X / Twitter',
                color: Colors.black,
                onTap: () {
                  _shareToX(url, texto);
                  Navigator.pop(context);
                },
              ),
              ShareOption(
                icon: Icons.more_horiz,
                label: 'Más',
                color: nc.textSecondary,
                onTap: () {
                  Share.share(texto);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enlace copiado al portapapeles')),
              );
            },
            icon: const Icon(Icons.link),
            label: const Text('Copiar enlace'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _shareToWhatsApp(String texto) async {
  final encoded = Uri.encodeComponent(texto);
  final schemeUri = Uri.parse('whatsapp://send?text=$encoded');
  if (await launchUrl(schemeUri, mode: LaunchMode.externalApplication)) return;
  final webUri = Uri.parse('https://wa.me/?text=$encoded');
  if (!await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
    await Share.share(texto);
  }
}

Future<void> _shareToFacebook(String url) async {
  final uri = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    await Share.share(url);
  }
}

Future<void> _shareToX(String url, String texto) async {
  final uri = Uri.parse(
      'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(texto)}');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    await Share.share('$texto\n$url');
  }
}
