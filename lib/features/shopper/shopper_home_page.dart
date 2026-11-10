import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/session_store.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../shared/status.dart';
import 'payment_page.dart';
import 'payments_history_page.dart';
import 'scan_cart_page.dart';

/// "Mi carrito": link the cart with its QR, see the items live and pay.
class ShopperHomePage extends StatefulWidget {
  const ShopperHomePage({super.key});

  @override
  State<ShopperHomePage> createState() => _ShopperHomePageState();
}

class _ShopperHomePageState extends State<ShopperHomePage> {
  MyCart? _myCart;
  bool _loading = true;
  bool _linking = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(AppConfig.shopperRefresh, (_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    try {
      final data = await ApiClient.instance.get('/me/cart');
      if (!mounted) return;
      setState(() {
        _myCart = MyCart.fromJson(data as Map<String, dynamic>);
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.status == 404) {
          _myCart = null;
          _error = null;
        } else if (!silent || _myCart == null) {
          _error = e.message;
        }
        _loading = false;
      });
    }
  }

  Future<void> _link(String cartId) async {
    setState(() => _linking = true);
    try {
      final data = await ApiClient.instance.post('/me/cart', {'cartId': cartId});
      if (!mounted) return;
      setState(() => _myCart = MyCart.fromJson(data as Map<String, dynamic>));
      showMessage(context, context.tr('shopper.linked', {'id': cartId}));
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  Future<void> _scan() async {
    final cartId = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const ScanCartPage()));
    if (cartId != null) await _link(cartId);
  }

  Future<void> _typeCode() async {
    final controller = TextEditingController(text: 'CART-');
    final cartId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('shopper.cartCode')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'CART-0427'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(context, parseCartId(controller.text)),
            child: Text(context.tr('shopper.link')),
          ),
        ],
      ),
    );
    if (cartId != null) await _link(cartId);
  }

  Future<void> _setBudget() async {
    final current = _myCart?.session.budget ?? 0;
    final controller = TextEditingController(text: current > 0 ? current.toStringAsFixed(0) : '');
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('shopper.budgetTitle')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: 'S/ ', hintText: '150'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 0.0), child: Text(context.tr('shopper.budgetRemove'))),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text.replaceAll(',', '.'))),
            child: Text(context.tr('common.save')),
          ),
        ],
      ),
    );
    if (value == null) return;
    try {
      final data = await ApiClient.instance.patch('/me/cart', {'budget': value});
      if (mounted) setState(() => _myCart = MyCart.fromJson(data as Map<String, dynamic>));
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    }
  }

  Future<void> _pay() async {
    final myCart = _myCart;
    if (myCart == null) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaymentPage(myCart: myCart)));
    _refresh(silent: true);
  }

  Future<void> _unlink() async {
    try {
      await ApiClient.instance.delete('/me/cart');
      if (mounted) setState(() => _myCart = null);
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionStore.current;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('shopper.hello', {'name': user?.firstName ?? ''})),
        actions: [
          IconButton(
            tooltip: context.tr('shopper.payments'),
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentsHistoryPage())),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => switch (value) {
              'unlink' => _unlink(),
              'es' || 'en' => I18n.setLang(value),
              _ => signOut(context),
            },
            itemBuilder: (_) => [
              if (_myCart != null) PopupMenuItem(value: 'unlink', child: Text(context.tr('shopper.unlink'))),
              PopupMenuItem(value: context.lang == 'es' ? 'en' : 'es', child: Text(context.lang == 'es' ? 'English' : 'Español')),
              PopupMenuItem(value: 'logout', child: Text(context.tr('common.signOut'))),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _myCart == null ? _buildLink() : _buildCart(_myCart!),
            ),
      bottomNavigationBar: _myCart == null ? null : _buildPayBar(_myCart!),
    );
  }

  Widget _buildLink() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_error != null) _Banner(icon: Icons.cloud_off, color: Brand.error, text: _error!),
        const SizedBox(height: 24),
        Container(
          height: 160,
          decoration: BoxDecoration(color: Brand.primaryContainer, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.qr_code_scanner, size: 88, color: Brand.primary),
        ),
        const SizedBox(height: 24),
        Text(context.tr('shopper.linkTitle'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          context.tr('shopper.linkText'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Brand.muted),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _linking ? null : _scan,
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(context.tr(_linking ? 'shopper.linking' : 'shopper.scan')),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _linking ? null : _typeCode,
          icon: const Icon(Icons.keyboard),
          label: Text(context.tr('shopper.typeCode')),
        ),
      ],
    );
  }

  Widget _buildCart(MyCart myCart) {
    final cart = myCart.cart;
    final session = myCart.session;
    final budget = session.budget;
    final over = budget > 0 && session.total > budget;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Brand.primary),
                    const SizedBox(width: 8),
                    Text(cart.id, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const Spacer(),
                    StatusChip(cart.status),
                  ],
                ),
                const SizedBox(height: 14),
                Text(money(session.total), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: Brand.ink)),
                Text('${context.tr('common.products', {'n': session.itemsCount})} · ${context.tr('shopper.order', {'id': session.id})}',
                    style: const TextStyle(color: Brand.muted)),
                if (cart.isPhysical) ...[const SizedBox(height: 4), DeviceBadge(online: cart.isOnline)],
                const SizedBox(height: 14),
                InkWell(
                  onTap: cart.status == 'PAID' ? null : _setBudget,
                  borderRadius: BorderRadius.circular(8),
                  child: budget <= 0
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [
                            const Icon(Icons.savings_outlined, size: 18, color: Brand.primary),
                            const SizedBox(width: 6),
                            Text(context.tr('shopper.setBudget'), style: const TextStyle(color: Brand.primary, fontWeight: FontWeight.w600)),
                          ]),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (session.total / budget).clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor: Brand.outline,
                                color: over ? Brand.error : (session.total / budget > 0.9 ? Brand.warning : Brand.green),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              over
                                  ? context.tr('shopper.overBudget', {'over': money(session.total - budget), 'budget': money(budget)})
                                  : context.tr('shopper.budgetLeft', {'left': money(budget - session.total), 'budget': money(budget)}),
                              style: TextStyle(color: over ? Brand.error : Brand.muted, fontWeight: over ? FontWeight.w600 : FontWeight.normal),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ..._statusBanner(cart),
        const SizedBox(height: 4),
        if (session.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(children: [
              const Icon(Icons.nfc, size: 48, color: Brand.muted),
              const SizedBox(height: 8),
              Text(context.tr('shopper.empty'), style: const TextStyle(color: Brand.muted)),
            ]),
          )
        else
          Card(
            child: Column(
              children: [
                for (final item in session.items)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Brand.primaryContainer,
                      child: Text('${item.quantity}', style: const TextStyle(color: Brand.primary, fontWeight: FontWeight.w700)),
                    ),
                    title: Text(item.name),
                    subtitle: Text(context.tr('common.eachPrice', {'price': money(item.unitPrice)})),
                    trailing: Text(money(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 90),
      ],
    );
  }

  List<Widget> _statusBanner(Cart cart) {
    final text = context.tr('shopper.banner.${cart.status}');
    return switch (cart.status) {
      'DISCREPANCY' => [_Banner(icon: Icons.scale, color: Brand.warning, text: text)],
      'LOCKED' => [_Banner(icon: Icons.lock, color: Brand.error, text: text)],
      'PAID' => [_Banner(icon: Icons.check_circle, color: Brand.green, text: text)],
      'OFFLINE' => [_Banner(icon: Icons.wifi_off, color: Brand.muted, text: text)],
      _ => const <Widget>[],
    };
  }

  Widget _buildPayBar(MyCart myCart) {
    final cart = myCart.cart;
    final session = myCart.session;
    final canPay = session.status == 'ACTIVE' && session.items.isNotEmpty && cart.status == 'IN_SESSION';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: canPay ? _pay : null,
          icon: Icon(cart.status == 'PAID' ? Icons.check : Icons.payments_outlined),
          label: Text(cart.status == 'PAID' ? context.tr('shopper.paid') : context.tr('shopper.pay', {'total': money(session.total)})),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
