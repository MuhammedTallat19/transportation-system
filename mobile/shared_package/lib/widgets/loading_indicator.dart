import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: TransportationAppDesignTokens.space12),
            Text(message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
