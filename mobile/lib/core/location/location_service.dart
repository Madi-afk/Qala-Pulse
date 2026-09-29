import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final locationProvider = Provider<LocationService>((ref) => LocationService());

class LocationService {
  Future<LatLng> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('gps_disabled');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('gps_denied');
    }
    final result = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return LatLng(result.latitude, result.longitude);
  }
}
