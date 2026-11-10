import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/session_store.dart';
import 'core/theme.dart';
import 'features/admin/admin_home_page.dart';
import 'features/auth/login_page.dart';
import 'features/shopper/shopper_home_page.dart';
import 'models/models.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.instance.onUnauthorized = () async {
    await SessionStore.clear();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  };
  runApp(const InnovaCartyApp());
}

class InnovaCartyApp extends StatelessWidget {
  const InnovaCartyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Innova Carty',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: Brand.theme(),
      home: const StartPage(),
    );
  }
}

/// The login decides the view: shopper ("Mi carrito") or store admin.
Widget homeFor(UserAccount user) => user.isAdmin ? const AdminHomePage() : const ShopperHomePage();

/// Opens the right view if the user was already signed in.
class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final Future<UserAccount?> _restore = SessionStore.restore();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserAccount?>(
      future: _restore,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        return user == null ? const LoginPage() : homeFor(user);
      },
    );
  }
}

Future<void> signOut(BuildContext context) async {
  await SessionStore.clear();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (_) => false,
  );
}
