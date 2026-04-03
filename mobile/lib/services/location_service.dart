import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;

  // Request location permissions
  Future<bool> requestPermissions() async {
    var status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      // Also request "always" for background geofencing
      final alwaysStatus = await Permission.locationAlways.request();
      return alwaysStatus.isGranted || status.isGranted;
    }
    return false;
  }

  // Check if location services are enabled
  Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await _checkPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  // Stream position updates (for map view)
  Stream<Position> getPositionStream({
    int distanceFilter = 50,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.balanced,
        distanceFilter: distanceFilter,
      ),
    );
  }

  // Start listening to significant location changes (battery-efficient)
  void startBackgroundTracking({
    required Function(Position) onPositionUpdate,
    int distanceFilter = 100,
  }) {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.balanced,
        distanceFilter: distanceFilter,
      ),
    ).listen(onPositionUpdate);
  }

  void stopBackgroundTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // Calculate distance between two points
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;

    final result = await Permission.locationWhenInUse.request();
    return result.isGranted;
  }

  void dispose() {
    _positionSubscription?.cancel();
  }
}
