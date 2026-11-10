import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/format.dart';
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
  /// Resolution saved in the audit log (English, like the console) and its Spanish label.
  static const _resolutions = {
    'Checked by supervisor': 'Revisado',
    'Item added to the order': 'Producto agregado',
    'Item removed from the cart': 'Producto retirado',
    'Shopper paid at the cashier': 'Pagó en caja',
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
          title: Text('Desbloquear ${widget.cartId}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(alignment: Alignment.centerLeft, child: Text('¿Qué pasó?', style: TextStyle(fontWeight: FontWeight.w600))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final option in _resolutions.entries)
                    ChoiceChip(
                      label: Text(option.value),
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
                decoration: const InputDecoration(labelText: 'PIN de supervisor'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Desbloquear'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ApiClient.instance.post('/carts/${widget.cartId}/unlock', {'pin': pin.text, 'resolution': resolution, 'note': 'Mobile app'});
      if (mounted) showMessage(context, '${widget.cartId} desbloqueado. El carrito lo sabrá en 2 segundos.');
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
        title: const Text('Liberar carrito'),
        content: const Text('Se cierra la compra actual y el carrito queda disponible para otro cliente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Liberar')),
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
              itemBuilder: (_) => const [PopupMenuItem(value: 'finish', child: Text('Liberar carrito'))],
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
                  label: const Text('Verificar y desbloquear'),
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
                Text('${cart.itemsCount} productos · ${cart.zone}', style: const TextStyle(color: Brand.muted)),
                if (session != null) ...[
                  const SizedBox(height: 8),
                  Text('Pedido ${session.id} · ${session.shopper}', style: const TextStyle(color: Brand.muted)),
                  if (cart.budget > 0) Text('Presupuesto ${money(cart.budget)}', style: const TextStyle(color: Brand.muted)),
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
                    subtitle: Text('${item.sku} · ${item.nominalWeight} g c/u'),
                    trailing: Text(money(item.subtotal)),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text('Actividad', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              if (_events.isEmpty) const ListTile(title: Text('Sin actividad todavía')),
              for (final e in _events)
                ListTile(
                  dense: true,
                  leading: Icon(Icons.circle, size: 12, color: toneColor(e.tone)),
                  title: Text(e.title),
                  subtitle: e.detail.isEmpty ? null : Text(e.detail),
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
                  Text('Peso medido ${session.measuredWeight} g · esperado ${session.expectedWeight} g'),
                  Text(
                    ok ? 'Dentro de la tolerancia (±${session.weightTolerance} g)' : 'Diferencia ${diff > 0 ? '+' : ''}$diff g (±${session.weightTolerance} g)',
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
