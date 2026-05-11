/// Modelo de dominio que representa una puja dentro de una subasta.
class AuctionBidModel {
  final String bidderName;
  final double amount;
  final DateTime? createdAt;

  const AuctionBidModel({
    required this.bidderName,
    required this.amount,
    this.createdAt,
  });

  factory AuctionBidModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['monto'] ?? json['amount'];
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '') ?? 0.0;

    final rawCreated = json['creado_en'] ?? json['created_at'] ?? json['fecha'];
    final createdAt = DateTime.tryParse(rawCreated?.toString() ?? '');

    return AuctionBidModel(
      bidderName:
          (json['pujador_nombre'] ?? json['bidder_name'] ?? json['usuario'])
                  ?.toString() ??
              'Pujador',
      amount: amount,
      createdAt: createdAt,
    );
  }
}
