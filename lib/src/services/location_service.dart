import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  
  // Location tracking settings
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 1, // Minimum distance (in meters) to trigger location updates
  );

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      return _currentPosition;
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  // Start location tracking
  void startLocationTracking({
    required Function(Position) onLocationUpdate,
    Function(String)? onError,
  }) {
    try {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      ).listen(
        (Position position) {
          _currentPosition = position;
          onLocationUpdate(position);
        },
        onError: (error) {
          if (onError != null) {
            onError('Location tracking error: $error');
          }
        },
      );
    } catch (e) {
      if (onError != null) {
        onError('Failed to start location tracking: $e');
      }
    }
  }

  // Stop location tracking
  void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  // Calculate distance between two points using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Calculate distance from GeoPoint objects
  double calculateDistanceFromGeoPoints(GeoPoint point1, GeoPoint point2) {
    return calculateDistance(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  // Convert meters to yards (golf standard)
  double metersToYards(double meters) {
    return meters * 1.09361;
  }

  // Convert yards to meters
  double yardsToMeters(double yards) {
    return yards * 0.9144;
  }

  // Get bearing between two points
  double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    double dLon = (lon2 - lon1) * pi / 180;
    double lat1Rad = lat1 * pi / 180;
    double lat2Rad = lat2 * pi / 180;
    
    double y = sin(dLon) * cos(lat2Rad);
    double x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
    
    double bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360; // Normalize to 0-360
  }

  // Check if position is accurate enough for golf tracking
  bool isPositionAccurate(Position position) {
    // Consider position accurate if within 5 meters
    return position.accuracy <= 5.0;
  }

  // Get distance to green (placeholder - in real app would use course data)
  Future<double?> getDistanceToGreen(Position currentPosition, GeoPoint greenPosition) async {
    try {
      final distanceInMeters = calculateDistanceFromGeoPoints(
        GeoPoint(currentPosition.latitude, currentPosition.longitude),
        greenPosition,
      );
      return metersToYards(distanceInMeters);
    } catch (e) {
      return null;
    }
  }

  // Check if two positions are significantly different (to avoid duplicate shots)
  bool isSignificantMovement(Position pos1, Position pos2, {double thresholdMeters = 3.0}) {
    final distance = calculateDistance(
      pos1.latitude,
      pos1.longitude,
      pos2.latitude,
      pos2.longitude,
    );
    return distance > thresholdMeters;
  }

  // Smooth GPS coordinates (simple moving average)
  List<Position> smoothPositions(List<Position> positions, {int windowSize = 3}) {
    if (positions.length < windowSize) return positions;
    
    List<Position> smoothed = [];
    
    for (int i = 0; i < positions.length; i++) {
      if (i < windowSize - 1) {
        smoothed.add(positions[i]);
        continue;
      }
      
      double latSum = 0, lonSum = 0;
      for (int j = i - windowSize + 1; j <= i; j++) {
        latSum += positions[j].latitude;
        lonSum += positions[j].longitude;
      }
      
      // Create smoothed position
      final avgLat = latSum / windowSize;
      final avgLon = lonSum / windowSize;
      
      // Use the latest position's other properties
      final latest = positions[i];
      smoothed.add(Position(
        longitude: avgLon,
        latitude: avgLat,
        timestamp: latest.timestamp,
        accuracy: latest.accuracy,
        altitude: latest.altitude,
        altitudeAccuracy: latest.altitudeAccuracy,
        heading: latest.heading,
        headingAccuracy: latest.headingAccuracy,
        speed: latest.speed,
        speedAccuracy: latest.speedAccuracy,
      ));
    }
    
    return smoothed;
  }

  // Get location permission status
  Future<LocationPermissionStatus> getPermissionStatus() async {
    final permission = await Geolocator.checkPermission();
    
    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionStatus.granted;
      default:
        return LocationPermissionStatus.unknown;
    }
  }

  // Request location permission
  Future<LocationPermissionStatus> requestPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      
      switch (permission) {
        case LocationPermission.denied:
          return LocationPermissionStatus.denied;
        case LocationPermission.deniedForever:
          return LocationPermissionStatus.deniedForever;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return LocationPermissionStatus.granted;
        default:
          return LocationPermissionStatus.unknown;
      }
    } catch (e) {
      return LocationPermissionStatus.unknown;
    }
  }

  // Convert Position to GeoPoint
  GeoPoint positionToGeoPoint(Position position) {
    return GeoPoint(position.latitude, position.longitude);
  }

  // Convert GeoPoint to readable string
  String geoPointToString(GeoPoint geoPoint) {
    return '${geoPoint.latitude.toStringAsFixed(6)}, ${geoPoint.longitude.toStringAsFixed(6)}';
  }

  // Check if location services are available
  Future<bool> isLocationServiceAvailable() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get current position without updating internal state
  Future<Position?> getPositionOnce() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  // Clean up resources
  void dispose() {
    stopLocationTracking();
  }
}

enum LocationPermissionStatus {
  unknown,
  denied,
  deniedForever,
  granted,
}