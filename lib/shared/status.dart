import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Label, color and icon of each cart status (same states as the console).
class CartStatusStyle {
  const CartStatusStyle(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  static CartStatusStyle of(String status) => switch (status) {
        'AVAILABLE' => const CartStatusStyle('Disponible', Brand.muted, Icons.shopping_cart_outlined),
        'IN_SESSION' => const CartStatusStyle('En compra', Brand.primary, Icons.shopping_cart),
        'DISCREPANCY' => const CartStatusStyle('Peso no coincide', Brand.warning, Icons.scale),
        'LOCKED' => const CartStatusStyle('Bloqueado', Brand.error, Icons.lock),
        'PAID' => const CartStatusStyle('Pagado', Brand.green, Icons.check_circle),
        'OFFLINE' => const CartStatusStyle('Sin conexión', Brand.muted, Icons.wifi_off),
        _ => CartStatusStyle(status, Brand.muted, Icons.help_outline),
      };
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final style = CartStatusStyle.of(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.color),
          const SizedBox(width: 4),
          Text(style.label, style: TextStyle(color: style.color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

Color severityColor(String severity) => switch (severity) {
      'CRITICAL' => Brand.error,
      'WARNING' => Brand.warning,
      _ => Brand.primary,
    };

IconData alertIcon(String type) => switch (type) {
      'GEOFENCE' => Icons.fence,
      'WEIGHT' => Icons.scale,
      'RFID' => Icons.sell,
      _ => Icons.battery_alert,
    };

Color toneColor(String tone) => switch (tone) {
      'OK' => Brand.green,
      'WARNING' => Brand.warning,
      'CRITICAL' => Brand.error,
      _ => Brand.primary,
    };

void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Brand.error : Brand.ink,
      behavior: SnackBarBehavior.floating,
    ));
}
