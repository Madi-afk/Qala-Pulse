import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/async_panel.dart';
import '../../shared/widgets/incident_card.dart';
import '../auth/auth_controller.dart';
import 'incident_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).asData?.value;
    final text = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(feedProvider);
        await ref.read(feedProvider('newest').future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            user == null
                ? context.l.citizenPlatform
                : context.l.greeting(user.displayName),
            style: text.bodyMedium?.copyWith(color: AppPalette.muted),
          ),
          const SizedBox(height: 12),
          Text(context.l.welcome, style: text.headlineLarge),
          const SizedBox(height: 12),
          Text(
            context.l.heroSubtitle,
            style: text.bodyMedium?.copyWith(color: AppPalette.muted),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/create'),
            icon: const Icon(Icons.add_a_photo_outlined, size: 20),
            label: Text(context.l.reportProblem),
          ),
          const SizedBox(height: 16),
          Material(
            color: AppPalette.softGreen,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.go('/map'),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 28,
                      color: AppPalette.green,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l.nearby, style: text.titleSmall),
                          const SizedBox(height: 4),
                          Text(context.l.mapExploreHint, style: text.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: AppPalette.green,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(context.l.highPriority, style: text.titleLarge),
          const SizedBox(height: 6),
          Text(context.l.prioritySectionHint, style: text.bodySmall),
          const SizedBox(height: 16),
          AsyncPanel(
            value: ref.watch(feedProvider('priority')),
            onRetry: () => ref.invalidate(feedProvider('priority')),
            builder: (items) => items.isEmpty
                ? EmptyState(
                    title: context.l.empty,
                    description: context.l.emptyFeedHint,
                    icon: Icons.location_city_outlined,
                  )
                : Column(
                    children: items
                        .take(3)
                        .map(
                          (item) => IncidentCard(
                            item,
                            key: ValueKey('priority-${item.id}'),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Text(context.l.latest, style: text.titleLarge),
              TextButton.icon(
                onPressed: () => context.push('/feed'),
                label: Text(context.l.allIncidents),
                icon: const Icon(Icons.arrow_forward, size: 16),
                iconAlignment: IconAlignment.end,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AsyncPanel(
            value: ref.watch(feedProvider('newest')),
            onRetry: () => ref.invalidate(feedProvider('newest')),
            builder: (items) => items.isEmpty
                ? EmptyState(
                    title: context.l.empty,
                    description: context.l.emptyFeedHint,
                    icon: Icons.add_location_alt_outlined,
                    action: TextButton(
                      onPressed: () => context.go('/create'),
                      child: Text(context.l.reportProblem),
                    ),
                  )
                : Column(
                    children: items.take(5).map(IncidentCard.new).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          Notice(context.l.honestNotice, icon: Icons.info_outline),
        ],
      ),
    );
  }
}
