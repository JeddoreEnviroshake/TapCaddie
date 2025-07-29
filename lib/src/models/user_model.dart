import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final List<Club> clubs;
  final Map<String, double> clubDistances;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.clubs = const [],
    this.clubDistances = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      clubs: (data['clubs'] as List<dynamic>?)
          ?.map((club) => Club.fromMap(club))
          .toList() ?? [],
      clubDistances: Map<String, double>.from(data['clubDistances'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'clubs': clubs.map((club) => club.toMap()).toList(),
      'clubDistances': clubDistances,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    List<Club>? clubs,
    Map<String, double>? clubDistances,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      clubs: clubs ?? this.clubs,
      clubDistances: clubDistances ?? this.clubDistances,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Club {
  final String id;
  final String name;
  final ClubType type;
  final String nfcTagId;
  final double? averageDistance;
  final int usageCount;

  Club({
    required this.id,
    required this.name,
    required this.type,
    required this.nfcTagId,
    this.averageDistance,
    this.usageCount = 0,
  });

  factory Club.fromMap(Map<String, dynamic> map) {
    return Club(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: ClubType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => ClubType.iron,
      ),
      nfcTagId: map['nfcTagId'] ?? '',
      averageDistance: map['averageDistance']?.toDouble(),
      usageCount: map['usageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'nfcTagId': nfcTagId,
      'averageDistance': averageDistance,
      'usageCount': usageCount,
    };
  }

  Club copyWith({
    String? id,
    String? name,
    ClubType? type,
    String? nfcTagId,
    double? averageDistance,
    int? usageCount,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      nfcTagId: nfcTagId ?? this.nfcTagId,
      averageDistance: averageDistance ?? this.averageDistance,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}

enum ClubType {
  driver,
  wood,
  hybrid,
  iron,
  wedge,
  putter,
}

extension ClubTypeExtension on ClubType {
  String get displayName {
    switch (this) {
      case ClubType.driver:
        return 'Driver';
      case ClubType.wood:
        return 'Wood';
      case ClubType.hybrid:
        return 'Hybrid';
      case ClubType.iron:
        return 'Iron';
      case ClubType.wedge:
        return 'Wedge';
      case ClubType.putter:
        return 'Putter';
    }
  }
}