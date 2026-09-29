import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/errors/app_error.dart';
import '../../core/localization/strings.dart';
import '../../shared/widgets/async_panel.dart';
import 'auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  bool registering = false, obscured = true;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(registering ? context.l.register : context.l.login),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(
                Icons.location_city_rounded,
                size: 64,
                color: Color(0xFF087E70),
              ),
              const SizedBox(height: 16),
              Text(
                context.l.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              Notice(context.l.honestNotice),
              Form(
                key: form,
                child: Column(
                  children: [
                    if (registering) ...[
                      TextFormField(
                        key: const ValueKey('auth-name'),
                        controller: name,
                        decoration: InputDecoration(
                          labelText: context.l.displayName,
                        ),
                        maxLength: 80,
                        validator: (v) => (v?.trim().length ?? 0) < 2
                            ? context.l.requiredField
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      key: const ValueKey('auth-email'),
                      controller: email,
                      autofillHints: const [AutofillHints.email],
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: context.l.email),
                      validator: (v) => v == null || !v.contains('@')
                          ? context.l.checkFields
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('auth-password'),
                      controller: password,
                      obscureText: obscured,
                      autofillHints: [
                        registering
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: context.l.password,
                        helperText: registering ? context.l.passwordHint : null,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscured = !obscured),
                          icon: Icon(
                            obscured
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          (v?.length ?? 0) < (registering ? 10 : 1)
                          ? context.l.passwordHint
                          : null,
                    ),
                    const SizedBox(height: 20),
                    if (auth.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(errorMessage(auth.error!, context.l)),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                if (!form.currentState!.validate()) return;
                                await ref
                                    .read(authProvider.notifier)
                                    .authenticate(
                                      email: email.text,
                                      password: password.text,
                                      name: registering ? name.text : null,
                                      language: Localizations.localeOf(
                                        context,
                                      ).languageCode,
                                    );
                                if (context.mounted &&
                                    ref.read(authProvider).asData?.value !=
                                        null) {
                                  context.go('/home');
                                }
                              },
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                registering
                                    ? context.l.register
                                    : context.l.login,
                              ),
                      ),
                    ),
                    TextButton(
                      onPressed: auth.isLoading
                          ? null
                          : () => setState(() => registering = !registering),
                      child: Text(
                        registering
                            ? context.l.haveAccount
                            : context.l.noAccount,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
