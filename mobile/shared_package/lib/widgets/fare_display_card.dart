import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../utils/currency_formatter.dart';

class FareDisplayCard extends StatelessWidget {
  final int fareCents;
  final String currency;
  final double? distanceKm;
  final int? etaMinutes;
  final String? routeName;
  final String? title;
  final String? subtitle;

  const FareDisplayCard({
    required this.fareCents,
    this.currency = 'EGP',
    this.distanceKm,
    this.etaMinutes,
    this.routeName,
    this.title,
    this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fareText = CurrencyFormatter.format(fareCents, currency: currency);
    final details = <String>[
      if (routeName != null) routeName!,
      if (distanceKm != null) '${distanceKm!.toStringAsFixed(1)} km',
      if (etaMinutes != null) '~$etaMinutes min',
    ].join(' · ');

    return Card(
      color: TransportationAppDesignTokens.primary.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(TransportationAppDesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title ?? 'Estimated fare', style: theme.textTheme.labelLarge),
            const SizedBox(height: TransportationAppDesignTokens.space8),
            Text(
              fareText,
              style: theme.textTheme.headlineMedium!.copyWith(
                  color: TransportationAppDesignTokens.primary,
                  fontWeight: FontWeight.w700),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: TransportationAppDesignTokens.space4),
              Text(subtitle ?? details, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
