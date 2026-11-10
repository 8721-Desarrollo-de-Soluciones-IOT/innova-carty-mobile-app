double _d(dynamic v) => v is num ? v.toDouble() : 0;
int _i(dynamic v) => v is num ? v.toInt() : 0;
String _s(dynamic v) => v?.toString() ?? '';
DateTime? _t(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

/// Signed-in account. The role decides the view: ADMIN or SHOPPER.
class UserAccount {
  UserAccount({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.jobTitle,
    required this.token,
  });

  final int id;
  final String email;
  final String fullName;
  final String role;
  final String jobTitle;
  final String token;

  bool get isAdmin => role == 'ADMIN';

  String get firstName => fullName.split(' ').first;

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        id: _i(json['id']),
        email: _s(json['email']),
        fullName: _s(json['fullName']),
        role: _s(json['role']),
        jobTitle: _s(json['jobTitle']),
        token: _s(json['token']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role,
        'jobTitle': jobTitle,
        'token': token,
      };
}

class Cart {
  Cart({
    required this.id,
    required this.status,
    required this.zone,
    required this.itemsCount,
    required this.total,
    required this.budget,
    required this.lastEvent,
    required this.lastEventAt,
    required this.battery,
    required this.sessionId,
    this.lastSeenAt,
  });

  final String id;
  final String status;
  final String zone;
  final int itemsCount;
  final double total;
  final double budget;
  final String lastEvent;
  final DateTime? lastEventAt;
  final int battery;
  final String? sessionId;

  /// Last time the ESP32 of the cart talked to the API. Only the physical prototype has it.
  final DateTime? lastSeenAt;

  bool get needsAttention => status == 'LOCKED' || status == 'DISCREPANCY';

  /// The real ESP32 prototype (demo carts never report from a device).
  bool get isPhysical => lastSeenAt != null;

  /// The device reported in the last 30 seconds (it polls every 2 s).
  bool get isOnline => lastSeenAt != null && DateTime.now().difference(lastSeenAt!).inSeconds < 30;

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        id: _s(json['id']),
        status: _s(json['status']),
        zone: _s(json['zone']),
        itemsCount: _i(json['itemsCount']),
        total: _d(json['total']),
        budget: _d(json['budget']),
        lastEvent: _s(json['lastEvent']),
        lastEventAt: _t(json['lastEventAt']),
        battery: _i(json['battery']),
        sessionId: json['sessionId']?.toString(),
        lastSeenAt: _t(json['lastSeenAt']),
      );
}

class SessionItem {
  SessionItem({
    required this.sku,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.nominalWeight,
  });

  final String sku;
  final String name;
  final int quantity;
  final double unitPrice;
  final int nominalWeight;

  double get subtotal => quantity * unitPrice;

  factory SessionItem.fromJson(Map<String, dynamic> json) => SessionItem(
        sku: _s(json['sku']),
        name: _s(json['name']),
        quantity: _i(json['quantity']),
        unitPrice: _d(json['unitPrice']),
        nominalWeight: _i(json['nominalWeight']),
      );
}

class ShoppingSession {
  ShoppingSession({
    required this.id,
    required this.cartId,
    required this.shopper,
    required this.status,
    required this.budget,
    required this.total,
    required this.expectedWeight,
    required this.measuredWeight,
    required this.weightTolerance,
    required this.startedAt,
    required this.paidAt,
    required this.paymentMethod,
    required this.items,
  });

  final String id;
  final String cartId;
  final String shopper;
  final String status;
  final double budget;
  final double total;
  final int expectedWeight;
  final int measuredWeight;
  final int weightTolerance;
  final DateTime? startedAt;
  final DateTime? paidAt;
  final String paymentMethod;
  final List<SessionItem> items;

  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory ShoppingSession.fromJson(Map<String, dynamic> json) => ShoppingSession(
        id: _s(json['id']),
        cartId: _s(json['cartId']),
        shopper: _s(json['shopper']),
        status: _s(json['status']),
        budget: _d(json['budget']),
        total: _d(json['total']),
        expectedWeight: _i(json['expectedWeight']),
        measuredWeight: _i(json['measuredWeight']),
        weightTolerance: _i(json['weightTolerance']),
        startedAt: _t(json['startedAt']),
        paidAt: _t(json['paidAt']),
        paymentMethod: _s(json['paymentMethod']),
        items: ((json['items'] as List?) ?? const [])
            .map((e) => SessionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Cart linked to the shopper app and its session.
class MyCart {
  MyCart({required this.cart, required this.session});

  final Cart cart;
  final ShoppingSession session;

  factory MyCart.fromJson(Map<String, dynamic> json) => MyCart(
        cart: Cart.fromJson(json['cart'] as Map<String, dynamic>),
        session: ShoppingSession.fromJson(json['session'] as Map<String, dynamic>),
      );
}

class Payment {
  Payment({
    required this.id,
    required this.operationCode,
    required this.cartId,
    required this.sessionId,
    required this.method,
    required this.amount,
    required this.status,
    required this.paidAt,
  });

  final int id;
  final String operationCode;
  final String cartId;
  final String sessionId;
  final String method;
  final double amount;
  final String status;
  final DateTime? paidAt;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: _i(json['id']),
        operationCode: _s(json['operationCode']),
        cartId: _s(json['cartId']),
        sessionId: _s(json['sessionId']),
        method: _s(json['method']),
        amount: _d(json['amount']),
        status: _s(json['status']),
        paidAt: _t(json['paidAt']),
      );
}

class AlertItem {
  AlertItem({
    required this.id,
    required this.cartId,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.zone,
    required this.createdAt,
    required this.status,
  });

  final int id;
  final String cartId;
  final String type;
  final String severity;
  final String title;
  final String description;
  final String zone;
  final DateTime? createdAt;
  final String status;

  bool get isOpen => status != 'RESOLVED';

  factory AlertItem.fromJson(Map<String, dynamic> json) => AlertItem(
        id: _i(json['id']),
        cartId: _s(json['cartId']),
        type: _s(json['type']),
        severity: _s(json['severity']),
        title: _s(json['title']),
        description: _s(json['description']),
        zone: _s(json['zone']),
        createdAt: _t(json['createdAt']),
        status: _s(json['status']),
      );
}

class CartEvent {
  CartEvent({
    required this.type,
    required this.title,
    required this.detail,
    required this.tone,
    required this.occurredAt,
  });

  final String type;
  final String title;
  final String detail;
  final String tone;
  final DateTime? occurredAt;

  factory CartEvent.fromJson(Map<String, dynamic> json) => CartEvent(
        type: _s(json['type']),
        title: _s(json['title']),
        detail: _s(json['detail']),
        tone: _s(json['tone']),
        occurredAt: _t(json['occurredAt']),
      );
}

/// What a QR of the cart screen asks for: link the app or pay
/// (INNOVACARTY|CART-0427|LINK or INNOVACARTY|CART-0427|PAY|12.50).
class CartQr {
  const CartQr(this.cartId, {this.pay = false});

  final String cartId;
  final bool pay;
}

CartQr? parseCartQr(String? raw) {
  final cartId = parseCartId(raw);
  if (cartId == null) return null;
  return CartQr(cartId, pay: raw!.toUpperCase().contains('|PAY'));
}

/// Reads the cart id from the QR of the cart screen ("INNOVACARTY|CART-0427|...",
/// a link with ?cart=CART-0427, the old "ORD-0427-001" text or just "CART-0427").
String? parseCartId(String? raw) {
  if (raw == null) return null;
  final cart = RegExp(r'CART-\d+', caseSensitive: false).firstMatch(raw);
  if (cart != null) return cart.group(0)!.toUpperCase();
  final order = RegExp(r'ORD-(\d{4})-', caseSensitive: false).firstMatch(raw);
  if (order != null) return 'CART-${order.group(1)}';
  return null;
}
