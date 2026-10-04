import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDanger;
  final bool isText;
  final IconData? icon;

  const AppButton({
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.isDanger = false,
    this.isText = false,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = isText
        ? TextButton.styleFrom(foregroundColor: theme.colorScheme.primary)
        : isDanger
            ? FilledButton.styleFrom(
                backgroundColor: TransportationAppDesignTokens.error,
                foregroundColor: Colors.white)
            : FilledButton.styleFrom(
                backgroundColor: isPrimary
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary,
                foregroundColor: Colors.white);

    final child = Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
      Text(label)
    ]);

    if (isText) {
      return TextButton(onPressed: onPressed, style: style, child: child);
    }
    return FilledButton(onPressed: onPressed, style: style, child: child);
  }
}
