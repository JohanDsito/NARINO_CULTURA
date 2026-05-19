import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/order_model.dart';
import '../providers/orders_provider.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Orden #$orderId',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: orderAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary, strokeWidth: 2),
        ),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (order) => _OrderBody(order: order),
      ),
    );
  }
}

// ─── Vista de error ───────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTypography.bodyMedium(color: textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cuerpo de la orden ───────────────────────────────────────────────────────

class _OrderBody extends ConsumerWidget {
  const _OrderBody({required this.order});

  final OrderModel order;

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final url =
        await ref.read(ordersProvider.notifier).initiatePayment(order.id);

    if (!context.mounted) return;

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              ref.read(ordersProvider).errorMessage ?? 'Error al iniciar pago'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _OrderHeader(order: order),
        const SizedBox(height: 14),
        Text(
          'Obras en esta orden',
          style: AppTypography.labelSemiBold(color: textSecondary),
        ),
        const SizedBox(height: 10),
        ...order.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OrderItemRow(item: item),
          ),
        ),
        if (order.isPendiente) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _pay(context, ref),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              icon: const Icon(Icons.credit_card_outlined),
              label: Text(
                'Completar pago',
                style: AppTypography.labelSemiBold(color: cs.onPrimary),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Encabezado de la orden ───────────────────────────────────────────────────

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});

  final OrderModel order;

  Color _estadoColor(String estado, bool isDark) {
    return switch (estado) {
      'completado' => AppColors.selvaAndina,
      'pendiente' => AppColors.oroAndino,
      'fallido' || 'reembolsado' => AppColors.error,
      _ => isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
    };
  }

  Color _estadoBg(String estado, bool isDark) {
    return switch (estado) {
      'completado' => AppColors.selvaPalida,
      'pendiente' => AppColors.oroPalido,
      _ => isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final indigoFg = isDark ? AppColors.indigoDark : AppColors.indigoNoche;

    final estadoColor = _estadoColor(order.estado, isDark);
    final estadoBg = _estadoBg(order.estado, isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Badge de estado
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  order.estado.toUpperCase(),
                  style: AppTypography.caption(color: estadoColor),
                ),
              ),
              const Spacer(),
              // Botón de comprobante PDF
              if (order.comprobantePdfUrl != null)
                IconButton(
                  tooltip: 'Ver comprobante PDF',
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  color: textMuted,
                  onPressed: () async {
                    final uri = Uri.tryParse(order.comprobantePdfUrl!);
                    if (uri != null) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 16, color: textMuted),
              const SizedBox(width: 6),
              Text(
                'Total: ${order.totalFormateado}',
                style: AppTypography.labelSemiBold(color: indigoFg),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Fila de ítem de la orden ─────────────────────────────────────────────────

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final dynamic item; // OrderItemModel

  String _fmt(double value) {
    final n = value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '\$$n COP';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final indigoFg = isDark ? AppColors.indigoDark : AppColors.indigoNoche;

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _ItemThumb(imageUrl: item.imagenUrl),
        ),
        title: Text(
          item.obraTitulo,
          style: AppTypography.labelSemiBold(color: textPrimary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            item.artistaNombre,
            style: AppTypography.caption(color: textMuted),
          ),
        ),
        trailing: Text(
          _fmt(item.precio),
          style: AppTypography.labelSemiBold(color: indigoFg),
        ),
      ),
    );
  }
}

// ─── Miniatura del ítem ───────────────────────────────────────────────────────

class _ItemThumb extends StatelessWidget {
  const _ItemThumb({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return const _ThumbFallback();
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      placeholder: (_, __) => const _ThumbFallback(loading: true),
      errorWidget: (_, __, ___) => const _ThumbFallback(),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      width: 48,
      height: 48,
      color: bgSubtle,
      child: Center(
        child: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.image_outlined, color: textMuted, size: 20),
      ),
    );
  }
}
