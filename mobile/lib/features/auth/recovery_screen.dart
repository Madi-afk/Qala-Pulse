import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/errors/app_error.dart';
import '../../core/localization/strings.dart';
import '../../shared/widgets/async_panel.dart';

class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});
  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  final email = TextEditingController();
  final form = GlobalKey<FormState>();
  bool loading = false, sent = false;
  Object? error;
  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await ref.read(apiProvider).post('/auth/forgot-password', {
        'email': email.text.trim(),
      });
      if (mounted) setState(() => sent = true);
    } catch (failure) {
      if (mounted) setState(() => error = failure);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l.forgotPassword)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (sent)
              Notice(context.l.recoverySent)
            else
              Form(
                key: form,
                child: Column(
                  children: [
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: context.l.email),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? context.l.checkFields
                          : null,
                    ),
                    const SizedBox(height: 20),
                    if (error != null)
                      Notice(
                        errorMessage(error!, context.l),
                        icon: Icons.error_outline,
                      ),
                    FilledButton(
                      onPressed: loading ? null : send,
                      child: loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l.sendRecovery),
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
