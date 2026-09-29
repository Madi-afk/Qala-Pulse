import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/localization/strings.dart';
import '../../core/permissions/permission_service.dart';
import '../../shared/widgets/async_panel.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).asData?.value;
    final locale = ref.watch(localeProvider);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const CircleAvatar(
          radius: 40,
          child: Icon(Icons.person_outline, size: 44),
        ),
        const SizedBox(height: 16),
        Text(
          user?.displayName ?? context.l.appName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (user != null) Text(user.email, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        if (user == null)
          FilledButton(
            onPressed: () => context.push('/auth'),
            child: Text(context.l.login),
          ),
        if (user != null) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.list_alt),
              title: Text(context.l.myIncidents),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/my-incidents/${user.id}'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(context.l.myConfirmations),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/my-confirmations'),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          context.l.language,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'ru', label: Text(context.l.russian)),
            ButtonSegment(value: 'kk', label: Text(context.l.kazakh)),
          ],
          selected: {locale.languageCode},
          onSelectionChanged: (selection) =>
              ref.read(localeProvider.notifier).setLanguage(selection.first),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(context.l.permissionSettings),
            onTap: PermissionService.openSettings,
          ),
        ),
        Notice(context.l.privacyNotice),
        Notice(context.l.honestNotice),
        if (user != null)
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    try {
                      await ref.read(authProvider.notifier).logout();
                    } catch (_) {}
                    if (mounted) setState(() => busy = false);
                  },
            icon: const Icon(Icons.logout),
            label: Text(busy ? context.l.loading : context.l.logout),
          ),
      ],
    );
  }
}
