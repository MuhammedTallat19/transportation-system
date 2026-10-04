import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

enum TripStatus { scheduled, inProgress, completed, cancelled }

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final TripStatus? status;

  const StatusBadge({required this.label, this.color, this.status, super.key});

  factory StatusBadge.fromStatus(String rawStatus) {
    final normalized = rawStatus.toUpperCase();
    TripStatus? mapped;
    if (['REQUESTED', 'ASSIGNED', 'SCHEDULED'].contains(normalized)) {
      mapped = TripStatus.scheduled;
    } else if (['STARTED', 'IN_PROGRESS'].contains(normalized)) {
      mapped = TripStatus.inProgress;
    } else if (normalized == 'COMPLETED') {
      mapped = TripStatus.completed;
    } else if (['CANCELLED', 'NO_SHOW'].contains(normalized)) {
      mapped = TripStatus.cancelled;
    }

    final displayLabel = mapped == TripStatus.scheduled
        ? 'Scheduled'
        : mapped == TripStatus.inProgress
            ? 'In progress'
            : mapped == TripStatus.completed
                ? 'Completed'
                : mapped == TripStatus.cancelled
                    ? 'Cancelled'
                    : rawStatus;

    return StatusBadge(
        label: displayLabel,
        status: mapped,
        color: TransportationAppDesignTokens.tripStatusColor(normalized));
  }

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? _statusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: resolvedColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: resolvedColor.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium!
            .copyWith(color: resolvedColor, fontWeight: FontWeight.w700),
      ),
    );
  }

  Color _statusColor() {
    switch (status) {
      case TripStatus.scheduled:
        return TransportationAppDesignTokens.info;
      case TripStatus.inProgress:
        return TransportationAppDesignTokens.accent;
      case TripStatus.completed:
        return TransportationAppDesignTokens.success;
      case TripStatus.cancelled:
        return TransportationAppDesignTokens.error;
      default:
        return TransportationAppDesignTokens.primary;
    }
  }
}
