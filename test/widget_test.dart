import 'package:flutter_test/flutter_test.dart';
import 'package:innova_carty/core/format.dart';
import 'package:innova_carty/models/models.dart';

void main() {
  group('QR of the cart', () {
    test('reads the cart id from the different QR formats', () {
      expect(parseCartId('INNOVACARTY|CART-0427|12.50'), 'CART-0427');
      expect(parseCartId('https://innova-carty.app/?cart=cart-0427'), 'CART-0427');
      expect(parseCartId('INNOVACARTY|ORD-0427-003|12.50'), 'CART-0427');
      expect(parseCartId('CART-0102'), 'CART-0102');
    });

    test('ignores QR codes that are not from a cart', () {
      expect(parseCartId('https://example.com'), isNull);
      expect(parseCartId(null), isNull);
    });
  });

  test('formats soles with two decimals', () {
    expect(money(12.5), 'S/ 12.50');
  });

  test('the role decides the view', () {
    final admin = UserAccount.fromJson({'id': 1, 'role': 'ADMIN', 'fullName': 'Lucía Medina'});
    final shopper = UserAccount.fromJson({'id': 2, 'role': 'SHOPPER', 'fullName': 'Camila Ríos'});
    expect(admin.isAdmin, isTrue);
    expect(shopper.isAdmin, isFalse);
    expect(shopper.firstName, 'Camila');
  });
}
