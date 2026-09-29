import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/api/api_client.dart';
import '../../core/localization/strings.dart';
import '../../core/location/location_service.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/incident_card.dart';
import '../feed/incident_repository.dart';
import 'city_map.dart';

class NearbyResult {
  const NearbyResult(this.items, this.hasMore);
  final List<Incident> items;
  final bool hasMore;
}

typedef NearbyQuery = (double, double, String?, double);
final nearbyProvider = FutureProvider.autoDispose
    .family<NearbyResult, NearbyQuery>((ref, query) async {
      ref.watch(incidentChangesProvider);
      final response = await ref
          .watch(apiProvider)
          .get(
            '/incidents/nearby',
            query: {
              'latitude': query.$1,
              'longitude': query.$2,
              'radius': query.$4,
              'limit': 200,
              if (query.$3 != null) 'category_id': query.$3,
            },
          );
      return NearbyResult(
        (response['items'] as List)
            .map((v) => Incident.fromJson(v as Map<String, dynamic>))
            .toList(),
        response['has_more'] == true,
      );
    });

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  LatLng center = const LatLng(43.2389, 76.8897);
  LatLng viewport = const LatLng(43.2389, 76.8897);
  double radius = 5000, viewportRadius = 5000;
  String? category;
  bool locating = false;
  @override
  Widget build(BuildContext context) {
    final query = (center.latitude, center.longitude, category, radius);
    final items = ref.watch(nearbyProvider(query));
    final categories = ref.watch(categoriesProvider).asData?.value ?? [];
    return Stack(
      children: [
        Positioned.fill(
          child: CityMap(
            center: center,
            incidents: items.asData?.value.items ?? [],
            onViewportChanged: (point, distance) => setState(() {
              viewport = point;
              viewportRadius = distance;
            }),
            categories: {for (final item in categories) item.id: item},
            onIncident: (item) => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (sheetContext) => Padding(
                padding: const EdgeInsets.all(20),
                child: IncidentCard(
                  item,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('/incident/${item.id}');
                  },
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                value: category,
                isExpanded: true,
                underline: const SizedBox(),
                hint: Text(context.l.allCategories),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(context.l.allCategories),
                  ),
                  ...categories.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'kk'
                            ? c.nameKk
                            : c.nameRu,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  category = value;
                  center = viewport;
                  radius = viewportRadius;
                }),
              ),
            ),
          ),
        ),
        Positioned(
          top: 84,
          left: 20,
          right: 20,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => setState(() {
                        center = viewport;
                        radius = viewportRadius;
                        ref.invalidate(
                          nearbyProvider((
                            center.latitude,
                            center.longitude,
                            category,
                            radius,
                          )),
                        );
                      }),
                      icon: const Icon(Icons.search),
                      label: Text(context.l.searchHere),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l.refreshMap,
                    onPressed: () => ref.invalidate(nearbyProvider(query)),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '${context.l.mapSearchArea(radius.round())}${items.asData?.value.hasMore == true ? '\n${context.l.mapResultsLimited}' : ''}',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (items.isLoading)
          const Positioned(
            top: 80,
            left: 20,
            right: 20,
            child: LinearProgressIndicator(),
          ),
        if (items.hasError)
          Positioned(
            bottom: 30,
            left: 16,
            right: 80,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(context.l.networkError),
                    TextButton(
                      onPressed: () => ref.invalidate(nearbyProvider(query)),
                      child: Text(context.l.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 40,
          right: 16,
          child: FloatingActionButton(
            onPressed: locating
                ? null
                : () async {
                    setState(() => locating = true);
                    try {
                      final point = await ref.read(locationProvider).current();
                      if (mounted) {
                        setState(() {
                          center = point;
                          viewport = point;
                        });
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l.gpsDenied)),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => locating = false);
                    }
                  },
            tooltip: context.l.currentLocation,
            child: locating
                ? const CircularProgressIndicator()
                : const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
