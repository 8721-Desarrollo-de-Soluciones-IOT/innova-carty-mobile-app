import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/i18n.dart';
import '../../core/session_store.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../shared/status.dart';
import 'sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = await ApiClient.instance.post('/authentication/sign-in', {
        'email': _email.text.trim().toLowerCase(),
        'password': _password.text,
      });
      final user = UserAccount.fromJson(data as Map<String, dynamic>);
      await SessionStore.save(user);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => homeFor(user)), (_) => false);
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fill(String email) {
    _email.text = email;
    _password.text = 'demo1234';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(children: [Expanded(child: _Logo()), LangSwitch()]),
                  const SizedBox(height: 32),
                  Text(context.tr('login.title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(context.tr('login.subtitle'), style: const TextStyle(color: Brand.muted)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(labelText: context.tr('login.email'), prefixIcon: const Icon(Icons.mail_outline)),
                    validator: (v) => v == null || !v.contains('@') ? context.tr('login.emailRequired') : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _hidden,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: context.tr('login.password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _hidden = !_hidden),
                      ),
                    ),
                    validator: (v) => v == null || v.length < 6 ? context.tr('login.passwordShort') : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(context.tr('login.submit')),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpPage())),
                    child: Text(context.tr('login.signUp')),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Brand.surfaceLow, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('login.demo'), style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.shopping_cart, size: 18),
                              label: Text(context.tr('login.demoShopper')),
                              onPressed: () => _fill('camila.rios@gmail.com'),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.admin_panel_settings, size: 18),
                              label: Text(context.tr('login.demoAdmin')),
                              onPressed: () => _fill('lucia.medina@retailco.pe'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: Brand.primaryContainer, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.shopping_cart_checkout, color: Brand.primary),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('INNOVA CARTY', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Brand.primary)),
            Text('Smart Cart', style: TextStyle(color: Brand.green, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
