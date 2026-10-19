import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_error.dart';
import '../../core/localization/strings.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/incident_card.dart';
import '../../shared/widgets/async_panel.dart';
import 'incident_repository.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key, this.authorId});
  final String? authorId;
  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  List<Incident> items = [];
  Object? error;
  int page = 1;
  bool busy = false, hasMore = true;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load({bool reset = false}) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
      if (reset) {
        page = 1;
        items = [];
        hasMore = true;
      }
    });
    try {
      final result = await ref
          .read(repositoryProvider)
          .feed(page: page, authorId: widget.authorId);
      if (mounted) {
        setState(() {
          items = [...items, ...result];
          page++;
          hasMore = result.length == 20;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.authorId == null
            ? context.l.allIncidents
            : context.l.myIncidents,
      ),
    ),
    body: RefreshIndicator(
      onRefresh: () => load(reset: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          ...items.map(IncidentCard.new),
          if (error != null) Text(errorMessage(error!, context.l)),
          if (busy) const Center(child: CircularProgressIndicator()),
          if (!busy && items.isEmpty && error == null)
            EmptyState(
              title: context.l.empty,
              description: context.l.emptyFeedHint,
              icon: Icons.location_city_outlined,
            ),
          if (!busy && (hasMore || error != null))
            OutlinedButton(
              onPressed: load,
              child: Text(error == null ? context.l.loadMore : context.l.retry),
            ),
        ],
      ),
    ),
  );
}
