import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class AppMapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const AppMapMarker._(
      {required this.icon, required this.color, this.size = 32});

  factory AppMapMarker.station({double size = 32}) => AppMapMarker._(
      icon: Icons.location_on_rounded,
      color: TransportationAppDesignTokens.primary,
      size: size);

  factory AppMapMarker.vehicle({double size = 32}) => AppMapMarker._(
      icon: Icons.directions_bus_rounded,
      color: TransportationAppDesignTokens.accent,
      size: size);

  factory AppMapMarker.passenger({double size = 32}) => AppMapMarker._(
      icon: Icons.person_pin_circle_rounded,
      color: TransportationAppDesignTokens.secondary,
      size: size);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Icon(icon, size: size * 0.55, color: Colors.white),
    );
  }
}
