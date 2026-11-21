import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/musician_model.dart';
import '../../widgets/musica_ui.dart';

class MusicalWorkCard extends StatelessWidget {
  const MusicalWorkCard({super.key, required this.obra});

  final MusicalWorkModel obra;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final o = obra;
    final enlaces = <(String, IconData, String)>[
      if ((o.youtubeUrl ?? '').isNotEmpty)
        ('YouTube', Icons.smart_display_outlined, o.youtubeUrl!),
      if ((o.spotifyTrackUrl ?? '').isNotEmpty)
        ('Spotify', Icons.graphic_eq_rounded, o.spotifyTrackUrl!),
      if ((o.audioUrl ?? '').isNotEmpty)
        ('Audio', Icons.play_circle_outline_rounded, o.audioUrl!),
      if (_urlDeEmbed(o.soundcloudEmbed) != null)
        ('SoundCloud', Icons.cloud_outlined, _urlDeEmbed(o.soundcloudEmbed)!),
    ];
    final meta = [
      if ((o.workType ?? '').isNotEmpty) _tipoObra(o.workType!),
      if (o.year != null) '${o.year}',
      if (o.durationSeconds != null)
        '${o.durationSeconds! ~/ 60}:${(o.durationSeconds! % 60).toString().padLeft(2, '0')}',
    ].join(' · ');

    return NcCard(
      padding: const EdgeInsets.all(12),
      gradientBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                    width: 64,
                    height: 64,
                    child: PortadaMusical(url: o.coverUrl)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTypography.labelSemiBold(color: nc.textPrimary)),
                    if (meta.isNotEmpty)
                      Text(meta,
                          style:
                              AppTypography.bodySmall(color: nc.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          if ((o.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(o.description!.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall(color: nc.textSecondary)),
          ],
          if (enlaces.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, icon, url) in enlaces)
                  NcPressable(
                    onTap: () => launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication),
                    semanticLabel: 'Escuchar en $label',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: nc.musica.tint,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: nc.musica.fill.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: nc.musica.ink),
                          const SizedBox(width: 6),
                          Text(label,
                              style: AppTypography.labelMedium(
                                      color: nc.musica.ink)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Tipos del backend (`MusicalWork.WorkType`).
  static String _tipoObra(String t) => switch (t.toUpperCase()) {
        'VIDEO' => 'Video musical',
        'LIVE' => 'En vivo',
        'STUDIO' => 'Estudio',
        'COVER' => 'Cover',
        'PODCAST' => 'Podcast',
        _ => t,
      };

  /// El backend guarda el `<iframe>` de SoundCloud; se extrae su URL.
  static String? _urlDeEmbed(String? embed) {
    if (embed == null || embed.trim().isEmpty) return null;
    if (embed.startsWith('http')) return embed.trim();
    final m = RegExp(r'src="([^"]+)"').firstMatch(embed);
    return m?.group(1);
  }
}
