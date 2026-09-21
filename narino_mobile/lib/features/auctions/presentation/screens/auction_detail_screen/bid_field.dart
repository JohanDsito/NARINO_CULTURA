import 'package:flutter/material.dart';

class BidField extends StatelessWidget {
  const BidField({
    super.key,
    required this.controller,
    required this.isBidding,
    required this.minPrice,
  });

  final TextEditingController controller;
  final bool isBidding;
  final double minPrice;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      enabled: !isBidding,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.payments_outlined),
        labelText: 'Nueva puja',
        hintText: 'Mín. \$${minPrice.toStringAsFixed(0)}',
      ),
    );
  }
}
