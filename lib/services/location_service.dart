import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// One GPS reading, with the speed already converted to km/h.
class SpeedReading {
  const SpeedReading({
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double speedKmh;
  final DateTime timestamp;
}

class LocationService {
  /// Asks for location permission. Returns true when we can track.
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Stream of speed readings. On Android a foreground-service notification keeps
  /// tracking alive while the screen is off.
  Stream<SpeedReading> speedStream() {
    final LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Speed Guardian',
          notificationText: 'Suivi de la vitesse en cours',
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );
    }

    return Geolocator.getPositionStream(locationSettings: settings).map((p) {
      // Position.speed is in m/s. Negative values mean "unknown".
      final mps = p.speed < 0 ? 0.0 : p.speed;
      return SpeedReading(
        latitude: p.latitude,
        longitude: p.longitude,
        speedKmh: mps * 3.6,
        timestamp: p.timestamp,
      );
    });
  }
}
