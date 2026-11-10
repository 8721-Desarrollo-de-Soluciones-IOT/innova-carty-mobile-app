import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/status.dart';

/// One cart for the supervisor: session, weight, timeline and unlock with PIN.
class CartDetailPage extends StatefulWidget {
  const CartDetailPage({super.key, required this.cartId});

  final String cartId;

  @override
  State<CartDetailPage> createState() => _CartDetailPageState();
}

class _CartDetailPageState extends State<CartDetailPage> {
  /// Resolution saved in the audit log (English, like the console) and the key of its label.
  static const _resolutions = {
    'Checked by supervisor': 'resolution.checked',
    'Item added to the order': 'resolution.added',
    'Item removed from the cart': 'resolution.removed',
    'Shopper paid at the cashier': 'resolution.cashier',
  };

  Cart? _cart;
  ShoppingSession? _session;
  List<CartEvent> _events = const [];
  String? _error;
  Timer? _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(AppConfig.adminRefresh, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final cart = Cart.fromJson(await ApiClient.instance.get('/carts/${widget.cartId}') as Map<String, dynamic>);
      ShoppingSession? session;
      if (cart.sessionId != null) {
        try {
          session = ShoppingSession.fromJson(await ApiClient.instance.get('/shopping-sessions/${cart.sessionId}') as Map<String, dynamic>);
        } on ApiException {
          session = null;
        }
      }
      final events = await ApiClient.instance.get('/cart-events', query: {'cartId': cart.id, '_order': 'desc', '_limit': '15'}) as List;
      if (!mounted) return;
      setState(() {
        _cart = cart;
        _session = session;
        _events = events.map((e) => CartEvent.fromJson(e as Map<String, dynamic>)).toList();
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _unlock() async {
    final pin = TextEditingController();
    String resolution = 'Checked by supervisor';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(context.tr('detail.unlockTitle', {'id': widget.cartId})),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(alignment: Alignment.centerLeft, child: Text(context.tr('detail.whatHappened'), style: const TextStyle(fontWeight: FontWeight.w600))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final option in _resolutions.entries)
                    ChoiceChip(
                      label: Text(context.tr(option.value)),
                      selected: resolution == option.key,
                      onSelected: (_) => setDialog(() => resolution = option.key),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pin,
                autofocus: true,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.tr('detail.pin')),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('common.cancel'))),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.tr('detail.unlock')),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ApiClient.instance.post('/carts/${widget.cartId}/unlock', {'pin': pin.text, 'resolution': resolution, 'note': 'Mobile app'});
      if (mounted) showMessage(context, context.tr('detail.unlocked', {'id': widget.cartId}));
      await _refresh();
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('detail.release')),
        content: Text(context.tr('detail.releaseText')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('common.cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr('detail.releaseOk'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.post('/carts/${widget.cartId}/finish');
      await _refresh();
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = _cart;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cartId),
        actions: [
          if (cart != null && cart.sessionId != null)
            PopupMenuButton<String>(
              onSelected: (_) => _finish(),
              itemBuilder: (_) => [PopupMenuItem(value: 'finish', child: Text(context.tr('detail.release')))],
            ),
        ],
      ),
      body: cart == null
          ? Center(child: _error == null ? const CircularProgressIndicator() : Text(_error!))
          : RefreshIndicator(onRefresh: _refresh, child: _buildBody(cart)),
      bottomNavigationBar: cart != null && cart.needsAttention
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Brand.error),
                  onPressed: _busy ? null : _unlock,
                  icon: const Icon(Icons.lock_open),
                  label: Text(context.tr('detail.verifyUnlock')),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(Cart cart) {
    final session = _session;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [StatusChip(cart.status), const Spacer(), Icon(Icons.battery_std, size: 18, color: Brand.muted), Text(' ${cart.battery}%')]),
                const SizedBox(height: 12),
                Text(money(cart.total), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                Text(context.tr('detail.itemsZone', {'n': cart.itemsCount, 'zone': context.st(cart.zone)}), style: const TextStyle(color: Brand.muted)),
                if (cart.isPhysical) ...[const SizedBox(height: 4), DeviceBadge(online: cart.isOnline)],
                if (session != null) ...[
                  const SizedBox(height: 8),
                  Text(context.tr('detail.order', {'id': session.id, 'shopper': context.st(session.shopper)}), style: const TextStyle(color: Brand.muted)),
                  if (cart.budget > 0) Text(context.tr('detail.budget', {'budget': money(cart.budget)}), style: const TextStyle(color: Brand.muted)),
                ],
              ],
            ),
          ),
        ),
        if (session != null && session.items.isNotEmpty) ...[
          const SizedBox(height: 12),
          _WeightCard(session: session),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                for (final item in session.items)
                  ListTile(
                    dense: true,
                    title: Text('${item.quantity} × ${item.name}'),
                    subtitle: Text(context.tr('detail.itemWeight', {'sku': item.sku, 'grams': item.nominalWeight})),
                    trailing: Text(money(item.subtotal)),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(context.tr('detail.activity'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              if (_events.isEmpty) ListTile(title: Text(context.tr('detail.noActivity'))),
              for (final e in _events)
                ListTile(
                  dense: true,
                  leading: Icon(Icons.circle, size: 12, color: toneColor(e.tone)),
                  title: Text(context.st(e.title)),
                  subtitle: e.detail.isEmpty ? null : Text(context.st(e.detail)),
                  trailing: Text(hourMinute(e.occurredAt), style: const TextStyle(color: Brand.muted)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.session});

  final ShoppingSession session;

  @override
  Widget build(BuildContext context) {
    final diff = session.measuredWeight - session.expectedWeight;
    final ok = diff.abs() <= session.weightTolerance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.scale, color: ok ? Brand.green : Brand.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('detail.weight', {'measured': session.measuredWeight, 'expected': session.expectedWeight})),
                  Text(
                    ok
                        ? context.tr('detail.weightOk', {'tolerance': session.weightTolerance})
                        : context.tr('detail.weightDiff', {'diff': '${diff > 0 ? '+' : ''}$diff', 'tolerance': session.weightTolerance}),
                    style: TextStyle(color: ok ? Brand.green : Brand.warning, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
