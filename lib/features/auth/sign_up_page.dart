import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/i18n.dart';
import '../../core/session_store.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../shared/status.dart';

/// Shopper sign-up. Staff accounts are created by the store.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = await ApiClient.instance.post('/authentication/sign-up', {
        'fullName': _name.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('signUp.title')), actions: const [Padding(padding: EdgeInsets.only(right: 12), child: LangSwitch())]),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.tr('signUp.text'), style: const TextStyle(color: Brand.muted)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: context.tr('signUp.name'), prefixIcon: const Icon(Icons.person_outline)),
                  validator: (v) => v == null || v.trim().length < 3 ? context.tr('signUp.nameRequired') : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: context.tr('login.email'), prefixIcon: const Icon(Icons.mail_outline)),
                  validator: (v) => v == null || !v.contains('@') ? context.tr('signUp.emailInvalid') : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(labelText: context.tr('login.password'), prefixIcon: const Icon(Icons.lock_outline)),
                  validator: (v) => v == null || v.length < 6 ? context.tr('login.passwordShort') : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(context.tr('signUp.submit')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
