import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/strings.dart';
import '../../shared/widgets/async_panel.dart';
import '../auth/auth_controller.dart';
import '../feed/incident_repository.dart';

final personalEventsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      path,
    ) async {
      final user = ref.watch(authProvider).asData?.value;
      if (user == null) return [];
      return ref.watch(repositoryProvider).items(path);
    });

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key, this.confirmations = false});
  final bool confirmations;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = confirmations
        ? '/users/me/confirmations'
        : '/users/me/notifications';
    if (ref.watch(authProvider).asData?.value == null) {
      return Center(
        child: FilledButton(
          onPressed: () => context.push('/auth'),
          child: Text(context.l.loginRequired),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(personalEventsProvider(path));
        await ref.read(personalEventsProvider(path).future);
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            confirmations ? context.l.myConfirmations : context.l.notifications,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (!confirmations) Notice(context.l.notificationHint),
          AsyncPanel(
            value: ref.watch(personalEventsProvider(path)),
            onRetry: () => ref.invalidate(personalEventsProvider(path)),
            builder: (items) => items.isEmpty
                ? Notice(context.l.noNotifications)
                : Column(
                    children: items
                        .map(
                          (item) => Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.notifications_none),
                              ),
                              title: Text(item['title'] as String),
                              subtitle: Text(
                                context.statusLabel(item['status'] as String),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push(
                                '/incident/${item['incident_id']}',
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
