import 'package:flutter/material.dart';

import '../../domain/models/price_observation.dart';

/// Menu de tri Price Intelligence.
class PriceIntelligenceSortButton extends StatelessWidget {
  const PriceIntelligenceSortButton({
    super.key,
    required this.sort,
    required this.onSortSelected,
  });

  final PriceIntelligenceSort sort;
  final ValueChanged<PriceIntelligenceSort> onSortSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PriceIntelligenceSort>(
      initialValue: sort,
      tooltip: 'Trier',
      onSelected: onSortSelected,
      itemBuilder: (context) => [
        for (final value in PriceIntelligenceSort.values)
          PopupMenuItem(
            value: value,
            child: Text(value.labelFr),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                sort.labelFr,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
