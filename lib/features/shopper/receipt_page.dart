import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

/// Proof of the simulated payment.
class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key, required this.payment, this.session});

  final Payment payment;
  final ShoppingSession? session;

  @override
  Widget build(BuildContext context) {
    final items = session?.items ?? const <SessionItem>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Comprobante'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          const CircleAvatar(
            radius: 40,
            backgroundColor: Brand.greenContainer,
            child: Icon(Icons.check_rounded, size: 52, color: Brand.green),
          ),
          const SizedBox(height: 16),
          const Text('¡Pago aprobado!', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(money(payment.amount), textAlign: TextAlign.center, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Brand.green)),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                _row('Método', payment.methodLabel),
                _row('N.° de operación', payment.operationCode),
                _row('Carrito', payment.cartId),
                _row('Pedido', payment.sessionId),
                _row('Fecha', dayHour(payment.paidAt)),
              ],
            ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  for (final item in items)
                    ListTile(
                      dense: true,
                      title: Text('${item.quantity} × ${item.name}'),
                      trailing: Text(money(item.subtotal)),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Brand.greenContainer, borderRadius: BorderRadius.circular(14)),
            child: const Row(
              children: [
                Icon(Icons.door_front_door_outlined, color: Brand.green),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Ya puedes salir: el carrito sabe que pagaste y no se bloqueará en la puerta.',
                      style: TextStyle(color: Brand.green, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Listo')),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return ListTile(
      dense: true,
      title: Text(label, style: const TextStyle(color: Brand.muted)),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
