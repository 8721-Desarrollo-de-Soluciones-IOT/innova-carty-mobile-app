/// The API and the carts write their texts in English (events, alerts, zones). These rules show
/// them in Spanish. Texts without a rule (product names, codes, amounts) are shown as they come.
const _categories = {
  'Produce': 'Frutas y verduras',
  'Bakery': 'Panadería',
  'Seafood': 'Pescados',
  'Dairy': 'Lácteos',
  'Beverages': 'Bebidas',
  'Meat': 'Carnes',
  'Household': 'Hogar',
  'Grocery': 'Abarrotes',
};

const _exact = {
  'Entrance': 'Entrada',
  'Charging bay': 'Zona de carga',
  'the exit': 'la salida',
  'Cart registered': 'Carrito registrado',
  'Cart online': 'Carrito en línea',
  'Shopping session started': 'Compra iniciada',
  'Session started': 'Compra iniciada',
  'Shopper took the cart': 'El cliente tomó el carrito',
  'Items updated': 'Productos actualizados',
  'Item added': 'Producto agregado',
  'Item removed': 'Producto retirado',
  'Physical prototype (ESP32) ready': 'Prototipo físico (ESP32) listo',
  'Guest session': 'Sesión de invitado',
  'Guest': 'Invitado',
  'Released': 'Liberado',
  'Charging': 'Cargando',
  'Heartbeat lost': 'Sin señal',
  'App linked': 'App vinculada',
  'Budget set': 'Presupuesto definido',
  'Weight discrepancy': 'Peso no coincide',
  'Weight discrepancy · payment paused': 'Peso no coincide · pago en pausa',
  'Weight back within tolerance': 'Peso dentro de la tolerancia otra vez',
  'Payment paused': 'Pago en pausa',
  'Geofence breach': 'Salida sin pagar',
  'Geofence breach · wheels locked': 'Salida sin pagar · ruedas bloqueadas',
  'Geofence crossed unpaid': 'Cruzó la salida sin pagar',
  'Order unpaid': 'Pedido sin pagar',
  'Wheels locked': 'Ruedas bloqueadas',
  'Unlocked with the supervisor key fob': 'Desbloqueado con el llavero del supervisor',
  'Checked by supervisor': 'Revisado por el supervisor',
  'Item added to the order': 'Producto agregado al pedido',
  'Item removed from the cart': 'Producto retirado del carrito',
  'Shopper paid at the cashier': 'El cliente pagó en caja',
  'Item placed again and read correctly': 'Producto pasado otra vez y leído bien',
  'Unregistered item removed from the cart': 'Producto sin registrar retirado del carrito',
  'Personal item (not store merchandise)': 'Objeto personal (no es mercadería)',
  'Shopper paid at assisted checkout': 'El cliente pagó en caja asistida',
  'False alarm, sensor recalibrated': 'Falsa alarma, sensor recalibrado',
  'Mobile app': 'App móvil',
  'Shopper left the store': 'El cliente salió de la tienda',
  'Session closed': 'Compra cerrada',
  'Checkout QR on screen': 'QR de pago en pantalla',
  'Checkout started': 'Pago iniciado',
  'Checkout cancelled': 'Pago cancelado',
  'Payment QR shown on the cart screen': 'QR de pago en la pantalla del carrito',
  'Exit clearance for 15 min': 'Salida autorizada por 15 min',
  'via mobile app': 'desde la app móvil',
  'Help requested': 'Pidió ayuda',
  'Shopper asked for help': 'El cliente pidió ayuda',
  'Unknown RFID tag': 'Etiqueta RFID desconocida',
  'Unreadable RFID tag': 'Etiqueta RFID ilegible',
  'Not in the catalog': 'No está en el catálogo',
  'Cart offline': 'Carrito sin conexión',
  'Floor supervisor': 'Supervisor de piso',
  'Shopper': 'Comprador',
};

const _paymentMethods = {'Card': 'Tarjeta', 'Card on cart': 'tarjeta en el carrito'};

String _method(String m) => _paymentMethods[m] ?? m;

String _zone(String text) {
  final exact = _exact[text];
  if (exact != null) return exact;
  final aisle = RegExp(r'^Aisle (\d+)(?: · (\w+))?$').firstMatch(text);
  if (aisle != null) {
    final category = aisle.group(2);
    return 'Pasillo ${aisle.group(1)}${category == null ? '' : ' · ${_categories[category] ?? category}'}';
  }
  final exit = RegExp(r'^Exit ?(\w*)$').firstMatch(text);
  if (exit != null) return exit.group(1)!.isEmpty ? 'Salida' : 'Salida ${exit.group(1)}';
  return text;
}

final List<(RegExp, String Function(RegExpMatch))> _rules = [
  (RegExp(r'^Unlocked by (.+)$'), (m) {
    final who = m.group(1)!;
    return 'Desbloqueado por ${who == 'key fob' ? 'el llavero' : who == 'supervisor' ? 'el supervisor' : who}';
  }),
  (RegExp(r'^Session (\S+) started$'), (m) => 'Pedido ${m.group(1)} iniciado'),
  (RegExp(r'^First connection of (\S+)$'), (m) => 'Primera conexión de ${m.group(1)}'),
  (RegExp(r'^(\d+) items · (S/ [\d.]+)$'), (m) => '${m.group(1)} productos · ${m.group(2)}'),
  (RegExp(r'^Weight (.+)$'), (m) => 'Peso ${translateServerText(m.group(1))}'),
  (RegExp(r'^([+−-]?\d+) g without (?:tag|RFID read)$'), (m) => '${m.group(1)} g sin etiqueta'),
  (RegExp(r'^([+−-]?\d+) g missing$'), (m) => '${m.group(1)} g faltantes'),
  (RegExp(r'^(\S+) measured (.+) g, expected (.+) g \(±(.+) g\)\.$'),
      (m) => '${m.group(1)} midió ${m.group(2)} g, se esperaban ${m.group(3)} g (±${m.group(4)} g).'),
  (RegExp(r'^(\S+) measured (.+) g without an RFID read\. Payment paused\.$'),
      (m) => '${m.group(1)} midió ${m.group(2)} g sin lectura RFID. Pago en pausa.'),
  (RegExp(r'^Geofence breach at (.+)$'), (m) => 'Salida sin pagar en ${_zone(m.group(1)!)}'),
  (RegExp(r'^Wheels locked at (.+)$'), (m) => 'Ruedas bloqueadas en ${_zone(m.group(1)!)}'),
  (RegExp(r'^Crossed (.+) without clearance$'), (m) => 'Cruzó ${_zone(m.group(1)!)} sin autorización'),
  (RegExp(r'^(\S+) reached (.+) with order unpaid \((S/ [\d.]+), (\d+) items\)\.$'),
      (m) => '${m.group(1)} llegó a ${_zone(m.group(2)!)} con el pedido sin pagar (${m.group(3)}, ${m.group(4)} productos).'),
  (RegExp(r'^Paid (S/ [\d.]+) with (.+)$'), (m) => 'Pagado ${m.group(1)} con ${_method(m.group(2)!)}'),
  (RegExp(r'^Payment approved · (.+)$'), (m) => 'Pago aprobado · ${_method(m.group(1)!)}'),
  (RegExp(r'^Payment confirmed \((.+)\)$'), (m) => 'Pago confirmado (${_method(m.group(1)!)})'),
  (RegExp(r'^(S/ [\d.]+) · operation (\S+)$'), (m) => '${m.group(1)} · operación ${m.group(2)}'),
  (RegExp(r'^(S/ [\d.]+) of (S/ [\d.]+)$'), (m) => '${m.group(1)} de ${m.group(2)}'),
  (RegExp(r'^(.+) linked the app$'), (m) => '${m.group(1)} vinculó la app'),
  (RegExp(r'^Linked to (.+) \(app\)$'), (m) => 'Vinculado a ${m.group(1)} (app)'),
  (RegExp(r'^Budget set to (S/ [\d.]+)$'), (m) => 'Presupuesto de ${m.group(1)}'),
  (RegExp(r'^Budget (\d+)% reached$'), (m) => 'Presupuesto al ${m.group(1)}%'),
  (RegExp(r'^(\S+) asked for assistance at (.+)\.$'), (m) => '${m.group(1)} pidió asistencia en ${_zone(m.group(2)!)}.'),
  (RegExp(r'^Tag (\S+) read by (\S+) is not in the catalog\.$'),
      (m) => 'La etiqueta ${m.group(1)} leída por ${m.group(2)} no está en el catálogo.'),
  (RegExp(r'^Unknown tag (\S+)$'), (m) => 'Etiqueta desconocida ${m.group(1)}'),
  (RegExp(r'^(\S+): resolved by floor staff\.$'), (m) => '${m.group(1)}: resuelto por el personal de piso.'),
  (RegExp(r'^(\S+) detected mass with a damaged tag \(SKU unknown\)\.$'),
      (m) => '${m.group(1)} detectó un producto con la etiqueta dañada (SKU desconocido).'),
  (RegExp(r'^(\S+) lost heartbeat\. Last battery reading (\d+)%\.$'),
      (m) => '${m.group(1)} perdió la señal. Última batería: ${m.group(2)}%.'),
  (RegExp(r'^Added (.+)$'), (m) => 'Agregó ${m.group(1)}'),
  (RegExp(r'^(Aisle .+|Exit ?\w*)$'), (m) => _zone(m.group(1)!)),
];

/// Spanish version of a text written by the API, or the same text when there is no rule.
String translateServerText(String? text) {
  if (text == null || text.isEmpty) return text ?? '';
  final exact = _exact[text];
  if (exact != null) return exact;
  for (final (pattern, render) in _rules) {
    final match = pattern.firstMatch(text);
    if (match != null) return render(match);
  }
  return text;
}
