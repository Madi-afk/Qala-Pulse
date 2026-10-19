import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../core/api/api_client.dart';
import '../../core/config/environment.dart';
import '../../core/errors/app_error.dart';
import '../../core/localization/strings.dart';
import '../../shared/widgets/async_panel.dart';
import '../../shared/widgets/status_badge.dart';
import '../auth/auth_controller.dart';
import '../feed/incident_repository.dart';
import '../map/city_map.dart';

class DetailsScreen extends ConsumerStatefulWidget {
  const DetailsScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends ConsumerState<DetailsScreen> {
  final comment = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> action(Future<void> Function() work, String success) async {
    if (ref.read(authProvider).asData?.value == null) {
      context.push('/auth');
      return;
    }
    if (busy) return;
    setState(() => busy = true);
    try {
      await work();
      ref.invalidate(incidentProvider(widget.id));
      ref.invalidate(timelineProvider(widget.id));
      ref.invalidate(commentsProvider(widget.id));
      ref.invalidate(feedProvider);
      ref.read(incidentChangesProvider.notifier).changed();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage(error, context.l))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> report({String? commentId}) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l.reportContent),
        content: TextField(
          controller: controller,
          maxLength: 1000,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: context.l.reportReason),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 5) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: Text(context.l.send),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason != null && mounted) {
      await action(() async {
        await ref.read(apiProvider).post('/content-reports', {
          if (commentId == null) 'incident_id': widget.id,
          'comment_id': ?commentId,
          'reason': reason,
        });
      }, context.l.reportSent);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l.appName),
      actions: [
        IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.home_outlined),
          tooltip: context.l.home,
        ),
      ],
    ),
    body: AsyncPanel(
      value: ref.watch(incidentProvider(widget.id)),
      onRetry: () => ref.invalidate(incidentProvider(widget.id)),
      builder: (item) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (item.media.isNotEmpty)
            SizedBox(
              height: 240,
              child: PageView(
                children: item.media
                    .map(
                      (m) => ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CachedNetworkImage(
                          imageUrl: Environment.mediaUrl(m['url'] as String),
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(item.status),
              Chip(label: Text('${context.l.severity}: ${item.severity}/10')),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final categories =
                  ref.watch(categoriesProvider).asData?.value ?? [];
              final matching = categories.where((c) => c.id == item.categoryId);
              return Text(
                matching.isEmpty
                    ? item.categoryId
                    : Localizations.localeOf(context).languageCode == 'kk'
                    ? matching.first.nameKk
                    : matching.first.nameRu,
              );
            },
          ),
          const SizedBox(height: 16),
          Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
          Notice(
            '${context.l.priority}: ${item.priorityScore.toStringAsFixed(0)}\n${item.priorityExplanation[Localizations.localeOf(context).languageCode] ?? ''}',
            icon: Icons.insights,
          ),
          Text('${context.l.confirmations}: ${item.confirmationCount}'),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CityMap(
                center: LatLng(item.latitude, item.longitude),
                selected: LatLng(item.latitude, item.longitude),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(item.address),
          Notice(context.l.honestNotice),
          if (busy) const LinearProgressIndicator(),
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => action(
                    () => ref
                        .read(repositoryProvider)
                        .confirm(item.id, 'still_exists'),
                    context.l.confirmationSent,
                  ),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(context.l.stillExists),
          ),
          if (item.status == 'resolved_pending_confirmation' ||
              item.status == 'resolved') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () => action(
                      () => ref
                          .read(repositoryProvider)
                          .confirm(item.id, 'resolved'),
                      context.l.confirmationSent,
                    ),
              icon: const Icon(Icons.task_alt),
              label: Text(context.l.reportResolution),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => action(
                      () => ref
                          .read(repositoryProvider)
                          .confirm(item.id, 'partially_resolved'),
                      context.l.confirmationSent,
                    ),
              child: Text(context.l.partiallyResolved),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            context.l.timeline,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AsyncPanel(
            value: ref.watch(timelineProvider(item.id)),
            onRetry: () => ref.invalidate(timelineProvider(item.id)),
            builder: (events) => Column(
              children: events
                  .map(
                    (event) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.radio_button_checked,
                        size: 18,
                        color: Color(0xFF087E70),
                      ),
                      title: Text(
                        context.statusLabel(event['status'] as String),
                      ),
                      subtitle: Text(
                        '${DateFormat(context.l.dateFormat).format(DateTime.parse(event['created_at'] as String).toLocal())}\n${event['note'] ?? ''}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l.comments,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AsyncPanel(
            value: ref.watch(commentsProvider(item.id)),
            onRetry: () => ref.invalidate(commentsProvider(item.id)),
            builder: (rows) => Column(
              children: rows
                  .map(
                    (row) => Card(
                      child: ListTile(
                        title: Text(row['author_name'] as String),
                        subtitle: Text(row['text'] as String),
                        trailing: IconButton(
                          icon: const Icon(Icons.flag_outlined, size: 18),
                          tooltip: context.l.reportContent,
                          onPressed: busy
                              ? null
                              : () => report(commentId: row['id'] as String),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          TextField(
            controller: comment,
            minLines: 2,
            maxLines: 4,
            maxLength: 2000,
            decoration: InputDecoration(labelText: context.l.addComment),
          ),
          OutlinedButton(
            onPressed: busy
                ? null
                : () => action(() async {
                    if (comment.text.trim().isEmpty) {
                      throw StateError('empty_comment');
                    }
                    await ref.read(apiProvider).post(
                      '/incidents/${item.id}/comments',
                      {'text': comment.text.trim()},
                    );
                    comment.clear();
                  }, context.l.commentSent),
            child: Text(context.l.send),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: busy ? null : report,
            icon: const Icon(Icons.flag_outlined),
            label: Text(context.l.reportContent),
          ),
        ],
      ),
    ),
  );
}
