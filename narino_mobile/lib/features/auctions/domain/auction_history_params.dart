class AuctionHistoryParams {
  final String mode;
  final String? estado;

  const AuctionHistoryParams({required this.mode, this.estado});

  @override
  bool operator ==(Object other) {
    return other is AuctionHistoryParams &&
        other.mode == mode &&
        other.estado == estado;
  }

  @override
  int get hashCode => Object.hash(mode, estado);
}
