import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../data/models.dart';

/// Itemised price breakdown, used in the booking flow and on receipts.
class PriceSummary extends StatelessWidget {
  const PriceSummary({super.key, required this.price, required this.tourTypeLabel});

  final PriceBreakdown price;
  final String tourTypeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _Line(
          label:
              '${formatMoney(price.unitPriceCents)} × ${price.travellers} '
              '${price.travellers == 1 ? 'traveller' : 'travellers'}',
          value: formatMoney(price.baseCents),
        ),
        if (price.tourTypeCents != 0)
          _Line(
            label: tourTypeLabel,
            value: '${price.tourTypeCents > 0 ? '+' : '−'} ${formatMoney(price.tourTypeCents.abs())}',
          ),
        if (price.insuranceCents > 0) _Line(label: 'Travel insurance', value: formatMoney(price.insuranceCents)),
        if (price.discountCents > 0)
          _Line(
            label: 'Promo ${price.promoCode ?? ''}',
            value: '− ${formatMoney(price.discountCents)}',
            color: AppColors.success,
          ),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
        Row(
          children: [
            Expanded(child: Text('Total', style: theme.textTheme.titleMedium)),
            Text(
              formatMoney(price.totalCents, forceDecimals: true),
              style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
            ),
          ],
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
