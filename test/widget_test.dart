import 'package:flutter_test/flutter_test.dart';
import 'package:innova_carty/core/format.dart';
import 'package:innova_carty/core/i18n.dart';
import 'package:innova_carty/core/messages.dart';
import 'package:innova_carty/core/server_texts.dart';
import 'package:innova_carty/models/models.dart';

void main() {
  group('QR of the cart', () {
    test('reads the cart id from the different QR formats', () {
      expect(parseCartId('INNOVACARTY|CART-0427|12.50'), 'CART-0427');
      expect(parseCartId('https://innova-carty.app/?cart=cart-0427'), 'CART-0427');
      expect(parseCartId('INNOVACARTY|ORD-0427-003|12.50'), 'CART-0427');
      expect(parseCartId('CART-0102'), 'CART-0102');
    });

    test('tells the link QR from the payment QR', () {
      expect(parseCartQr('INNOVACARTY|CART-0427|LINK')!.pay, isFalse);
      final pay = parseCartQr('INNOVACARTY|CART-0427|PAY|12.50')!;
      expect(pay.cartId, 'CART-0427');
      expect(pay.pay, isTrue);
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

  group('Languages', () {
    test('Spanish by default and English with the selector', () {
      expect(I18n.t('login.submit'), 'Ingresar');
      I18n.lang.value = 'en';
      expect(I18n.t('login.submit'), 'Sign in');
      expect(I18n.server('Geofence breach · wheels locked'), 'Geofence breach · wheels locked');
      I18n.lang.value = 'es';
    });

    test('API texts are shown in Spanish', () {
      expect(translateServerText('Geofence breach · wheels locked'), 'Salida sin pagar · ruedas bloqueadas');
      expect(translateServerText('Paid S/ 12.50 with Yape'), 'Pagado S/ 12.50 con Yape');
      expect(translateServerText('Aisle 4 · Dairy'), 'Pasillo 4 · Lácteos');
      expect(translateServerText('+1 Leche entera 1 L'), '+1 Leche entera 1 L');
    });

    test('both languages have the same keys', () {
      final es = messages['es']!.keys.toSet();
      final en = messages['en']!.keys.toSet();
      expect(es.difference(en), isEmpty);
      expect(en.difference(es), isEmpty);
    });
  });
}
