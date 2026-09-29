import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../shared/models/models.dart';

final repositoryProvider = Provider<IncidentRepository>(
  (ref) => IncidentRepository(ref.watch(apiProvider)),
);
final categoriesProvider = FutureProvider<List<IncidentCategory>>(
  (ref) => ref.watch(repositoryProvider).categories(),
);
final feedProvider = FutureProvider.family<List<Incident>, String>(
  (ref, sort) => ref.watch(repositoryProvider).feed(sort: sort),
);
final incidentProvider = FutureProvider.family<Incident, String>(
  (ref, id) => ref.watch(repositoryProvider).details(id),
);
final timelineProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
      (ref, id) =>
          ref.watch(repositoryProvider).items('/incidents/$id/timeline'),
    );
final commentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
      (ref, id) =>
          ref.watch(repositoryProvider).items('/incidents/$id/comments'),
    );

class IncidentRepository {
  IncidentRepository(this.api);
  final ApiClient api;
  Future<List<IncidentCategory>> categories() async =>
      ((await api.dio.get<List<dynamic>>('/categories')).data!)
          .map((v) => IncidentCategory.fromJson(v as Map<String, dynamic>))
          .toList();
  Future<List<Incident>> feed({
    String sort = 'newest',
    int page = 1,
    String? authorId,
  }) async {
    final data = await api.get(
      '/incidents',
      query: {
        'sort': sort,
        'page': page,
        'page_size': 20,
        'author_id': ?authorId,
      },
    );
    return (data['items'] as List)
        .map((v) => Incident.fromJson(v as Map<String, dynamic>))
        .toList();
  }

  Future<Incident> details(String id) async =>
      Incident.fromJson(await api.get('/incidents/$id'));
  Future<List<Map<String, dynamic>>> items(String path) async =>
      ((await api.get(path))['items'] as List).cast<Map<String, dynamic>>();
  Future<Incident> publish(Map<String, dynamic> payload, String key) async =>
      Incident.fromJson(await api.post('/incidents', payload, key: key));
  Future<void> confirm(String id, String status) async {
    await api.post('/incidents/$id/confirmations', {'status': status});
  }
}
