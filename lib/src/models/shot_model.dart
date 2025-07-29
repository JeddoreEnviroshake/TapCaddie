import 'package:cloud_firestore/cloud_firestore.dart';

class ShotModel {
  final String id;
  final String userId;
  final String roundId;
  final int holeNumber;
  final int shotNumber;
  final String clubId;
  final String clubName;
  final GeoPoint startPosition;
  final GeoPoint? endPosition;
  final double? distance;
  final DateTime timestamp;
  final ShotResult result;
  final Map<String, dynamic> metadata;

  ShotModel({
    required this.id,
    required this.userId,
    required this.roundId,
    required this.holeNumber,
    required this.shotNumber,
    required this.clubId,
    required this.clubName,
    required this.startPosition,
    this.endPosition,
    this.distance,
    required this.timestamp,
    this.result = ShotResult.unknown,
    this.metadata = const {},
  });

  factory ShotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShotModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      roundId: data['roundId'] ?? '',
      holeNumber: data['holeNumber'] ?? 1,
      shotNumber: data['shotNumber'] ?? 1,
      clubId: data['clubId'] ?? '',
      clubName: data['clubName'] ?? '',
      startPosition: data['startPosition'] ?? const GeoPoint(0, 0),
      endPosition: data['endPosition'],
      distance: data['distance']?.toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      result: ShotResult.values.firstWhere(
        (result) => result.name == data['result'],
        orElse: () => ShotResult.unknown,
      ),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'roundId': roundId,
      'holeNumber': holeNumber,
      'shotNumber': shotNumber,
      'clubId': clubId,
      'clubName': clubName,
      'startPosition': startPosition,
      'endPosition': endPosition,
      'distance': distance,
      'timestamp': Timestamp.fromDate(timestamp),
      'result': result.name,
      'metadata': metadata,
    };
  }

  bool get hasEndPosition => endPosition != null;
  
  bool get hasDistance => distance != null && distance! > 0;
  
  String get distanceDisplay {
    if (!hasDistance) return 'Unknown';
    return '${distance!.round()} yds';
  }

  ShotModel copyWith({
    String? id,
    String? userId,
    String? roundId,
    int? holeNumber,
    int? shotNumber,
    String? clubId,
    String? clubName,
    GeoPoint? startPosition,
    GeoPoint? endPosition,
    double? distance,
    DateTime? timestamp,
    ShotResult? result,
    Map<String, dynamic>? metadata,
  }) {
    return ShotModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roundId: roundId ?? this.roundId,
      holeNumber: holeNumber ?? this.holeNumber,
      shotNumber: shotNumber ?? this.shotNumber,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      startPosition: startPosition ?? this.startPosition,
      endPosition: endPosition ?? this.endPosition,
      distance: distance ?? this.distance,
      timestamp: timestamp ?? this.timestamp,
      result: result ?? this.result,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum ShotResult {
  fairway,
  rough,
  hazard,
  green,
  sand,
  outOfBounds,
  unknown,
}

extension ShotResultExtension on ShotResult {
  String get displayName {
    switch (this) {
      case ShotResult.fairway:
        return 'Fairway';
      case ShotResult.rough:
        return 'Rough';
      case ShotResult.hazard:
        return 'Hazard';
      case ShotResult.green:
        return 'Green';
      case ShotResult.sand:
        return 'Sand';
      case ShotResult.outOfBounds:
        return 'Out of Bounds';
      case ShotResult.unknown:
        return 'Unknown';
    }
  }

  String get emoji {
    switch (this) {
      case ShotResult.fairway:
        return '🟢';
      case ShotResult.rough:
        return '🟡';
      case ShotResult.hazard:
        return '🔵';
      case ShotResult.green:
        return '⚪';
      case ShotResult.sand:
        return '🟤';
      case ShotResult.outOfBounds:
        return '🔴';
      case ShotResult.unknown:
        return '❓';
    }
  }
}