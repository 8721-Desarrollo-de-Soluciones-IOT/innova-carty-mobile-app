import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/status.dart';
import 'receipt_page.dart';

/// Payment methods. The payment is simulated: no money moves, the API approves it.
enum PayMethod {
  yape('YAPE', Color(0xFF742284), Icons.phone_iphone),
  plin('PLIN', Color(0xFF00A19B), Icons.phone_android),
  card('CARD', Brand.primary, Icons.credit_card);

  const PayMethod(this.code, this.color, this.icon);

  final String code;
  final Color color;
  final IconData icon;
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, required this.myCart});

  final MyCart myCart;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PayMethod? _method;
  bool _paying = false;
  final _cardNumber = TextEditingController(text: '4111 1111 1111 1111');
  final _cardExpiry = TextEditingController(text: '12/30');
  final _cardCvv = TextEditingController(text: '123');

  @override
  void dispose() {
    _cardNumber.dispose();
    _cardExpiry.dispose();
    _cardCvv.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final method = _method;
    if (method == null) return;
    setState(() => _paying = true);
    try {
      // Simulated wallet / bank confirmation time.
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      final data = await ApiClient.instance.post('/payments', {
        'cartId': widget.myCart.cart.id,
        'method': method.code,
      });
      final payment = Payment.fromJson(data as Map<String, dynamic>);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ReceiptPage(payment: payment, session: widget.myCart.session),
      ));
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.myCart.session;
    final method = _method;
    return Scaffold(
      appBar: AppBar(
          title: Text(method == null ? context.tr('pay.choose') : context.tr('pay.with', {'method': context.tr('pay.method.${method.code}')}))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(backgroundColor: Brand.primaryContainer, child: Icon(Icons.storefront, color: Brand.primary)),
              title: const Text('Innova Carty · Surco Store #01', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${widget.myCart.cart.id} · ${context.tr('common.products', {'n': session.itemsCount})}'),
              trailing: Text(money(session.total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 16),
          if (method == null) ...[
            for (final m in PayMethod.values) ...[
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(backgroundColor: m.color, child: Icon(m.icon, color: Colors.white)),
                  title: Text(context.tr('pay.method.${m.code}'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => _method = m),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ] else if (method == PayMethod.card)
            _buildCardForm()
          else
            _buildWallet(method, session.total),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Brand.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(context.tr('pay.simulated'), style: const TextStyle(color: Brand.muted, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: method == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: method.color),
                      onPressed: _paying ? null : _confirm,
                      child: _paying
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
                              const SizedBox(width: 12),
                              Text(context.tr('pay.processing')),
                            ])
                          : Text(context.tr(method == PayMethod.card ? 'pay.payTotal' : 'pay.confirmTotal', {'total': money(session.total)})),
                    ),
                    TextButton(
                      onPressed: _paying ? null : () => setState(() => _method = null),
                      child: Text(context.tr('pay.change')),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWallet(PayMethod method, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: method.color, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Icon(method.icon, size: 56, color: Colors.white),
          const SizedBox(height: 12),
          Text(context.tr('pay.method.${method.code}'), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Text(context.tr('pay.payTo'), style: const TextStyle(color: Colors.white70)),
          const Text('Innova Carty SAC', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Text(money(total), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Text(context.tr('pay.confirmWallet', {'method': context.tr('pay.method.${method.code}')}),
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _cardNumber,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: context.tr('pay.cardNumber'), prefixIcon: const Icon(Icons.credit_card)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(controller: _cardExpiry, decoration: InputDecoration(labelText: context.tr('pay.cardExpiry'))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cardCvv,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: context.tr('pay.cardCvv')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(context.tr('pay.cardTest'), style: const TextStyle(color: Brand.muted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
