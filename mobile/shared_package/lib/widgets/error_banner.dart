import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorBanner({required this.message, this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: TransportationAppDesignTokens.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: TransportationAppDesignTokens.error.withOpacity(0.25))),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: TransportationAppDesignTokens.error),
        const SizedBox(width: 12),
        Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: TransportationAppDesignTokens.error))),
        if (onRetry != null) ...[
          const SizedBox(width: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry'))
        ],
      ]),
    );
  }
}
