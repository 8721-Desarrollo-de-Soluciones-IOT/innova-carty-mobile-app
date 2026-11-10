import 'package:flutter/material.dart';

import '../core/i18n.dart';
import '../core/theme.dart';

/// Label key, color and icon of each cart status (same states as the console).
class CartStatusStyle {
  const CartStatusStyle(this.label, this.color, this.icon);

  /// i18n key (or the raw status when it is unknown).
  final String label;
  final Color color;
  final IconData icon;

  static CartStatusStyle of(String status) => switch (status) {
        'AVAILABLE' => const CartStatusStyle('status.AVAILABLE', Brand.muted, Icons.shopping_cart_outlined),
        'IN_SESSION' => const CartStatusStyle('status.IN_SESSION', Brand.primary, Icons.shopping_cart),
        'DISCREPANCY' => const CartStatusStyle('status.DISCREPANCY', Brand.warning, Icons.scale),
        'LOCKED' => const CartStatusStyle('status.LOCKED', Brand.error, Icons.lock),
        'PAID' => const CartStatusStyle('status.PAID', Brand.green, Icons.check_circle),
        'OFFLINE' => const CartStatusStyle('status.OFFLINE', Brand.muted, Icons.wifi_off),
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
          Text(context.tr(style.label), style: TextStyle(color: style.color, fontWeight: FontWeight.w600, fontSize: 12)),
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

/// "Physical prototype · online" badge for the real ESP32 cart.
class DeviceBadge extends StatelessWidget {
  const DeviceBadge({super.key, required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? Brand.green : Brand.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.memory, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '${context.tr('device.real')} · ${context.tr(online ? 'device.online' : 'device.offline')}',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// ES | EN selector.
class LangSwitch extends StatelessWidget {
  const LangSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.lang;
    return ToggleButtons(
      isSelected: [for (final l in I18n.supported) l == current],
      onPressed: (i) => I18n.setLang(I18n.supported[i]),
      borderRadius: BorderRadius.circular(20),
      constraints: const BoxConstraints(minHeight: 32, minWidth: 44),
      selectedColor: Colors.white,
      fillColor: Brand.primary,
      color: Brand.muted,
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      children: [for (final l in I18n.supported) Text(l.toUpperCase())],
    );
  }
}
