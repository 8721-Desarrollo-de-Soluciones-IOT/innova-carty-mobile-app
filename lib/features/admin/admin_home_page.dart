import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/session_store.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../shared/status.dart';
import 'cart_detail_page.dart';

/// Store admin view: live fleet and alerts (same data as the Web Console).
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

enum _CartFilter { all, attention, active, paid }

class _AdminHomePageState extends State<AdminHomePage> {
  int _tab = 0;
  List<Cart> _carts = const [];
  List<AlertItem> _alerts = const [];
  bool _loading = true;
  String? _error;
  Timer? _timer;
  _CartFilter _filter = _CartFilter.all;
  bool _onlyOpen = true;

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
      final results = await Future.wait([
        ApiClient.instance.get('/carts'),
        ApiClient.instance.get('/alerts', query: {'_sort': 'createdAt', '_order': 'desc'}),
      ]);
      if (!mounted) return;
      setState(() {
        _carts = (results[0] as List).map((e) => Cart.fromJson(e as Map<String, dynamic>)).toList();
        _alerts = (results[1] as List).map((e) => AlertItem.fromJson(e as Map<String, dynamic>)).toList();
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _openCart(String cartId) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CartDetailPage(cartId: cartId))).then((_) => _refresh());
  }

  Future<void> _setAlertStatus(AlertItem alert, String status) async {
    try {
      await ApiClient.instance.patch('/alerts/${alert.id}', {'status': status});
      await _refresh();
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final openAlerts = _alerts.where((a) => a.isOpen).length;
    final user = SessionStore.current;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Innova Carty · Tienda', style: TextStyle(fontWeight: FontWeight.w700)),
            Text('${user?.fullName ?? ''} · ${user?.jobTitle ?? 'Admin'}', style: const TextStyle(fontSize: 12, color: Brand.muted)),
          ],
        ),
        actions: [
          IconButton(tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout), onPressed: () => signOut(context)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: _refresh, child: _tab == 0 ? _buildCarts() : _buildAlerts()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Carritos'),
          NavigationDestination(
            icon: Badge(isLabelVisible: openAlerts > 0, label: Text('$openAlerts'), child: const Icon(Icons.notifications_outlined)),
            selectedIcon: Badge(isLabelVisible: openAlerts > 0, label: Text('$openAlerts'), child: const Icon(Icons.notifications)),
            label: 'Alertas',
          ),
        ],
      ),
    );
  }

  Widget _buildCarts() {
    final active = _carts.where((c) => const ['IN_SESSION', 'DISCREPANCY', 'LOCKED', 'PAID'].contains(c.status)).length;
    final attention = _carts.where((c) => c.needsAttention).length;
    final carts = _carts.where((c) => switch (_filter) {
          _CartFilter.all => true,
          _CartFilter.attention => c.needsAttention,
          _CartFilter.active => c.status == 'IN_SESSION',
          _CartFilter.paid => c.status == 'PAID',
        }).toList()
      ..sort((a, b) {
        if (a.needsAttention != b.needsAttention) return a.needsAttention ? -1 : 1;
        return a.id.compareTo(b.id);
      });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Brand.error))),
        Row(
          children: [
            _Kpi(label: 'Activos', value: '$active', color: Brand.primary),
            const SizedBox(width: 10),
            _Kpi(label: 'Atención', value: '$attention', color: attention > 0 ? Brand.error : Brand.muted),
            const SizedBox(width: 10),
            _Kpi(label: 'Flota', value: '${_carts.length}', color: Brand.ink),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in _CartFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(switch (f) {
                      _CartFilter.all => 'Todos',
                      _CartFilter.attention => 'Atención',
                      _CartFilter.active => 'En compra',
                      _CartFilter.paid => 'Pagados',
                    }),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final cart in carts) ...[
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Icon(CartStatusStyle.of(cart.status).icon, color: CartStatusStyle.of(cart.status).color),
              title: Row(
                children: [
                  Text(cart.id, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  StatusChip(cart.status),
                ],
              ),
              subtitle: Text('${cart.zone} · ${cart.itemsCount} prod. · ${money(cart.total)}\n${cart.lastEvent} · ${timeAgo(cart.lastEventAt)}'),
              isThreeLine: true,
              onTap: () => _openCart(cart.id),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildAlerts() {
    final alerts = _onlyOpen ? _alerts.where((a) => a.isOpen).toList() : _alerts;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Solo alertas abiertas'),
          value: _onlyOpen,
          onChanged: (v) => setState(() => _onlyOpen = v),
        ),
        if (alerts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Text('Sin alertas. Todo en orden.', textAlign: TextAlign.center, style: TextStyle(color: Brand.muted)),
          ),
        for (final alert in alerts) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(alertIcon(alert.type), color: severityColor(alert.severity)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text(timeAgo(alert.createdAt), style: const TextStyle(color: Brand.muted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(alert.description),
                  const SizedBox(height: 4),
                  Text('${alert.cartId} · ${alert.zone} · ${_alertStatus(alert.status)}', style: const TextStyle(color: Brand.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(onPressed: () => _openCart(alert.cartId), child: const Text('Ver carrito')),
                      if (alert.status == 'OPEN')
                        TextButton(onPressed: () => _setAlertStatus(alert, 'ACKNOWLEDGED'), child: const Text('Reconocer')),
                      if (alert.isOpen)
                        TextButton(onPressed: () => _setAlertStatus(alert, 'RESOLVED'), child: const Text('Resolver')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  static String _alertStatus(String status) => switch (status) {
        'OPEN' => 'Abierta',
        'ACKNOWLEDGED' => 'Reconocida',
        'RESOLVED' => 'Resuelta',
        _ => status,
      };
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: const TextStyle(color: Brand.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
