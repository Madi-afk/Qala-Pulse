import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/strings.dart';
import '../../shared/models/models.dart';

class CityMap extends StatefulWidget {
  const CityMap({
    super.key,
    required this.center,
    this.incidents = const [],
    this.selected,
    this.onSelect,
    this.onIncident,
    this.categories = const {},
    this.onViewportChanged,
  });
  final LatLng center;
  final List<Incident> incidents;
  final LatLng? selected;
  final ValueChanged<LatLng>? onSelect;
  final ValueChanged<Incident>? onIncident;
  final Map<String, IncidentCategory> categories;
  final void Function(LatLng center, double radius)? onViewportChanged;
  @override
  State<CityMap> createState() => _CityMapState();
}

class _CityMapState extends State<CityMap> {
  Color categoryColor(Incident incident) {
    final raw = widget.categories[incident.categoryId]?.color.replaceFirst(
      '#',
      '',
    );
    return Color(int.tryParse('FF${raw ?? '087E70'}', radix: 16) ?? 0xFF087E70);
  }

  IconData categoryIcon(Incident incident) =>
      switch (widget.categories[incident.categoryId]?.icon) {
        'road_damage' => Icons.car_crash_outlined,
        'open_manhole' => Icons.warning_amber_rounded,
        'garbage' => Icons.delete_outline,
        'street_light' => Icons.lightbulb_outline,
        'water_leak' => Icons.water_drop_outlined,
        'sidewalk_damage' => Icons.directions_walk,
        _ => Icons.location_on,
      };
  final controller = MapController();
  bool ready = false;
  @override
  void didUpdateWidget(CityMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (ready && oldWidget.center != widget.center) {
      controller.move(widget.center, controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlutterMap(
    mapController: controller,
    options: MapOptions(
      initialCenter: widget.center,
      initialZoom: 14,
      onMapReady: () => ready = true,
      onTap: (_, point) => widget.onSelect?.call(point),
      onPositionChanged: (camera, hasGesture) {
        if (hasGesture) {
          final radius = const Distance().as(
            LengthUnit.Meter,
            camera.center,
            camera.visibleBounds.northEast,
          );
          widget.onViewportChanged?.call(
            camera.center,
            radius.clamp(100, 20000),
          );
        }
      },
    ),
    children: [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'kz.qalapulse.qalapulse',
        maxNativeZoom: 19,
      ),
      if (widget.incidents.isNotEmpty)
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 45,
            size: const Size(42, 42),
            markers: widget.incidents
                .map(
                  (item) => Marker(
                    point: LatLng(item.latitude, item.longitude),
                    width: 42,
                    height: 48,
                    child: Semantics(
                      label:
                          '${item.title}, ${context.statusLabel(item.status)}',
                      button: true,
                      child: GestureDetector(
                        onTap: () => widget.onIncident?.call(item),
                        child: CircleAvatar(
                          backgroundColor: categoryColor(item),
                          child: Icon(
                            item.status == 'resolved'
                                ? Icons.check_circle_outline
                                : categoryIcon(item),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
            builder: (context, markers) => Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF087E70),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${markers.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      if (widget.selected != null)
        MarkerLayer(
          markers: [
            Marker(
              point: widget.selected!,
              width: 48,
              height: 48,
              child: const Icon(
                Icons.location_pin,
                color: Color(0xFFD35B40),
                size: 48,
              ),
            ),
          ],
        ),
      RichAttributionWidget(
        attributions: [
          TextSourceAttribution(
            context.l.mapAttribution,
            onTap: () =>
                launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
          ),
        ],
      ),
    ],
  );
}
