import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import 'receipt_page.dart';

/// "Mis pagos": receipts of the shopper.
class PaymentsHistoryPage extends StatefulWidget {
  const PaymentsHistoryPage({super.key});

  @override
  State<PaymentsHistoryPage> createState() => _PaymentsHistoryPageState();
}

class _PaymentsHistoryPageState extends State<PaymentsHistoryPage> {
  late Future<List<Payment>> _payments = _load();

  Future<List<Payment>> _load() async {
    final data = await ApiClient.instance.get('/me/payments') as List;
    return data.map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pagos')),
      body: FutureBuilder<List<Payment>>(
        future: _payments,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(snapshot.error.toString(), textAlign: TextAlign.center),
                TextButton(onPressed: () => setState(() => _payments = _load()), child: const Text('Reintentar')),
              ]),
            );
          }
          final payments = snapshot.data!;
          if (payments.isEmpty) {
            return const Center(child: Text('Aún no tienes pagos.', style: TextStyle(color: Brand.muted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final p = payments[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Brand.greenContainer, child: Icon(Icons.receipt, color: Brand.green)),
                  title: Text('${money(p.amount)} · ${p.methodLabel}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${p.cartId} · ${dayHour(p.paidAt)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReceiptPage(payment: p))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
