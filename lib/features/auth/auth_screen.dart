import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../state/providers.dart';
import '../../widgets/brand_logo.dart';

enum AuthMode { login, register }

/// Sign-in and sign-up in one screen. After success the user is returned to
/// [redirectTo] (e.g. the booking they were about to make).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.mode, this.redirectTo});

  final AuthMode mode;
  final String? redirectTo;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  late AuthMode _mode = widget.mode;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  bool get _isLogin => _mode == AuthMode.login;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = ref.read(authControllerProvider.notifier);
    try {
      if (_isLogin) {
        await auth.login(_email.text.trim(), _password.text);
      } else {
        await auth.register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          phone: _phone.text.trim(),
        );
      }
      if (!mounted) return;
      final target = widget.redirectTo;
      if (target != null && target.startsWith('/')) {
        context.go(target);
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemo() {
    setState(() {
      _mode = AuthMode.login;
      _email.text = 'demo@example.com';
      _password.text = 'Password123!';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: BrandLogo(size: 120, withWordmark: true)),
                      const SizedBox(height: 16),
                      Text(
                        _isLogin ? 'Welcome back' : 'Create your account',
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin
                            ? 'Sign in to book trips and manage your bookings.'
                            : 'Start planning your next adventure.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 28),
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: theme.colorScheme.onErrorContainer),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!_isLogin) ...[
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.trim().length < 2) ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                        validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '')
                            ? null
                            : 'Enter a valid email address',
                      ),
                      if (!_isLogin) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          decoration: const InputDecoration(
                            labelText: 'Phone (optional)',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty || RegExp(r'^\+?[0-9\s-]{8,16}$').hasMatch(v.trim()))
                              ? null
                              : 'Enter a valid phone number',
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: [_isLogin ? AutofillHints.password : AutofillHints.newPassword],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          helperText: _isLogin ? null : 'At least 8 characters, with a letter and a number',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscure ? 'Show password' : 'Hide password',
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter your password';
                          if (_isLogin) return null;
                          if (v.length < 8) return 'Password must be at least 8 characters';
                          if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'[0-9]').hasMatch(v)) {
                            return 'Use at least one letter and one number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                            : Text(_isLogin ? 'Sign in' : 'Create account'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() {
                          _mode = _isLogin ? AuthMode.register : AuthMode.login;
                          _error = null;
                        }),
                        child: Text(_isLogin ? "Don't have an account? Sign up" : 'Already have an account? Sign in'),
                      ),
                      if (_isLogin && AppConfig.showDemoLogin)
                        TextButton.icon(
                          onPressed: _fillDemo,
                          icon: const Icon(Icons.bolt_rounded),
                          label: const Text('Use demo account'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
