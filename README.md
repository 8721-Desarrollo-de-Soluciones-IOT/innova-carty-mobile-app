# Innova Carty · Mobile App (Flutter)

One app, two views. **The account you sign in with decides what you see:**

| Role | View | What it does |
| :--- | :--- | :--- |
| `SHOPPER` | **Mi carrito** | Scan the QR on the cart screen, see the items read by RFID live, set a budget and pay with **Yape, Plin or card** (simulated). Receipts in "Mis pagos". |
| `ADMIN` | **Tienda** | Live fleet, alerts (geofence, weight, RFID, help), cart detail with weight check and timeline, **unlock with supervisor PIN**, release a cart. |

It uses the same API as the cart (ESP32) and the Web Console: [`innova-carty-backend`](https://github.com/8721-Desarrollo-de-Soluciones-IOT/innova-carty-backend) (Spring Boot on Render + Supabase).

## Languages

Spanish by default, English with the **ES | EN** selector (login, admin top bar and the shopper menu). The choice is saved on the phone. Texts that the API writes in English (events, alerts, zones) are shown in Spanish by `lib/core/server_texts.dart`.

## Demo accounts (password `demo1234`)

- Shopper: `camila.rios@gmail.com` (or create your own account in the app)
- Admin: `lucia.medina@retailco.pe`, PIN `2468`

## Run it in Android Studio

Requires Flutter 3.27 or newer and the Flutter plugin of Android Studio.

```bash
git clone https://github.com/8721-Desarrollo-de-Soluciones-IOT/innova-carty-mobile-app.git
cd innova-carty-mobile-app
flutter create . --org com.innovacarty --project-name innova_carty --platforms android
flutter pub get
flutter run
```

`flutter create .` only generates the Android project files that are missing; it keeps `lib/`, `test/` and `AndroidManifest.xml` (internet and camera permissions).

If the build asks for a higher `minSdk` (camera scanner), open `android/app/build.gradle.kts` and set `minSdk = 23`.

### Another backend URL

The API URL is in `lib/core/config.dart`. To try a backend running on your laptop:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.35:8080/api/v1
```
## Build the APK

```bash
flutter build apk --release
```

The file is `build/app/outputs/flutter-apk/app-release.apk`. Copy it to an Android phone and open it.

## Tests

```bash
flutter test
```

`test/widget_test.dart` checks the QR reader (link and payment QR), the money format, the view by role and the two languages.

## Structure

```
lib/
├── core/        # API client (JWT), session, config, theme, formats
├── models/      # Cart, ShoppingSession, Payment, AlertItem, CartEvent, UserAccount
├── features/
│   ├── auth/    # Login (role decides the view) and shopper sign-up
│   ├── shopper/ # Mi carrito, QR scanner, payment (Yape / Plin / card), receipt, history
│   └── admin/   # Fleet, alerts and cart detail with PIN unlock
└── shared/      # Status colors and labels
```

## Payment flow

1. The cart screen shows a QR with its id (`CART-0427`).
2. The shopper scans it: `POST /api/v1/me/cart` links the cart to the app.
3. "Pagar" → Yape / Plin / card → `POST /api/v1/payments`. No real money moves.
4. The cart reads `PAID` within 2 seconds and lets the shopper leave without locking the wheels.



### QR formats

| QR | Content | What the app does |
| :--- | :--- | :--- |
| Link | `INNOVACARTY\|CART-0427\|LINK` | Links the cart to the shopper (`POST /me/cart`) |
| Payment | `INNOVACARTY\|CART-0427\|PAY\|total` | Opens Yape / Plin / card (US08) |
