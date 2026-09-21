import 'package:flutter/material.dart';

import '../../../domain/auction_model.dart';
import 'auction_card.dart';

class AuctionList extends StatelessWidget {
  const AuctionList({super.key, required this.auctions, required this.now});

  final List<AuctionModel> auctions;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: auctions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => AuctionCard(auction: auctions[i], now: now),
    );
  }
}
