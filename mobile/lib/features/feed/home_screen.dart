import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/strings.dart';
import '../../shared/widgets/async_panel.dart';
import '../../shared/widgets/incident_card.dart';
import '../auth/auth_controller.dart';
import 'incident_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).asData?.value;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(feedProvider);
        await ref.read(feedProvider('newest').future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                user.displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF075E54), Color(0xFF149482)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_city_rounded,
                  color: Color(0xFFC1F3D8),
                  size: 42,
                ),
                const SizedBox(height: 20),
                Text(
                  context.l.welcome,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l.heroSubtitle,
                  style: const TextStyle(color: Color(0xFFD9F5EA), height: 1.5),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD4F1B9),
                    foregroundColor: const Color(0xFF123B30),
                  ),
                  onPressed: () => context.go('/create'),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(context.l.reportProblem),
                ),
              ],
            ),
          ),
          Notice(context.l.honestNotice),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l.nearby,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go('/map'),
                icon: const Icon(Icons.map_outlined),
                label: Text(context.l.map),
              ),
            ],
          ),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.near_me_outlined)),
              title: Text(context.l.nearby),
              subtitle: Text(
                context.l.locationHint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => context.go('/map'),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l.highPriority,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          AsyncPanel(
            value: ref.watch(feedProvider('priority')),
            onRetry: () => ref.invalidate(feedProvider('priority')),
            builder: (items) => items.isEmpty
                ? Notice(context.l.empty)
                : Column(
                    children: items.take(3).map(IncidentCard.new).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l.latest,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/feed'),
                child: Text(context.l.allIncidents),
              ),
            ],
          ),
          AsyncPanel(
            value: ref.watch(feedProvider('newest')),
            onRetry: () => ref.invalidate(feedProvider('newest')),
            builder: (items) => items.isEmpty
                ? Notice(context.l.empty)
                : Column(
                    children: items.take(5).map(IncidentCard.new).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
