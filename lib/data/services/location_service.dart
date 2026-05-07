import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class LocationService extends GetxService {
  final Rx<Position?> currentPosition = Rx(null);
  final RxBool isInsideGeofence = false.obs;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Location', 'Location services are disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPosition.value = position;
      return position;
    } catch (e) {
      return null;
    }
  }

  /// Returns distance in meters between two coordinates
  double distanceBetween({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Check if current position is within geofence
  bool checkGeofence({
    required double officeLat,
    required double officeLng,
    required double radiusInMeters,
    required Position currentPos,
  }) {
    final distance = distanceBetween(
      startLat: officeLat,
      startLng: officeLng,
      endLat: currentPos.latitude,
      endLng: currentPos.longitude,
    );
    final inside = distance <= radiusInMeters;
    isInsideGeofence.value = inside;
    return inside;
  }
}
