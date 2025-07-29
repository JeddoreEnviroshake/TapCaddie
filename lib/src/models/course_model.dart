import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String name;
  final String location;
  final List<Hole> holes;
  final double? rating;
  final int slope;
  final DateTime createdAt;

  CourseModel({
    required this.id,
    required this.name,
    required this.location,
    required this.holes,
    this.rating,
    required this.slope,
    required this.createdAt,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      holes: (data['holes'] as List<dynamic>?)
          ?.map((hole) => Hole.fromMap(hole))
          .toList() ?? [],
      rating: data['rating']?.toDouble(),
      slope: data['slope'] ?? 113,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'location': location,
      'holes': holes.map((hole) => hole.toMap()).toList(),
      'rating': rating,
      'slope': slope,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  int get totalPar => holes.fold(0, (sum, hole) => sum + hole.par);
  
  double get totalDistance => holes.fold(0, (sum, hole) => sum + hole.distance);
}

class Hole {
  final int number;
  final int par;
  final double distance; // in yards
  final String description;
  final GeoPoint? teePosition;
  final GeoPoint? greenPosition;
  final List<GeoPoint> hazards;

  Hole({
    required this.number,
    required this.par,
    required this.distance,
    this.description = '',
    this.teePosition,
    this.greenPosition,
    this.hazards = const [],
  });

  factory Hole.fromMap(Map<String, dynamic> map) {
    return Hole(
      number: map['number'] ?? 1,
      par: map['par'] ?? 4,
      distance: map['distance']?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      teePosition: map['teePosition'],
      greenPosition: map['greenPosition'],
      hazards: (map['hazards'] as List<dynamic>?)
          ?.cast<GeoPoint>() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'par': par,
      'distance': distance,
      'description': description,
      'teePosition': teePosition,
      'greenPosition': greenPosition,
      'hazards': hazards,
    };
  }
}

// Predefined template courses
class CourseTemplates {
  static List<CourseModel> get templates => [
    _createDefaultCourse(),
    _createChampionshipCourse(),
    _createExecutiveCourse(),
  ];

  static CourseModel _createDefaultCourse() {
    return CourseModel(
      id: 'template_default',
      name: 'Default 18-Hole Course',
      location: 'Template Course',
      slope: 113,
      rating: 72.0,
      createdAt: DateTime.now(),
      holes: List.generate(18, (index) {
        final holeNumber = index + 1;
        int par;
        double distance;
        
        // Typical par distribution
        if ([1, 4, 8, 12, 15].contains(holeNumber)) {
          par = 5; // Par 5s
          distance = 520 + (index % 3) * 30; // 520-580 yards
        } else if ([3, 6, 11, 14, 17].contains(holeNumber)) {
          par = 3; // Par 3s  
          distance = 150 + (index % 4) * 20; // 150-210 yards
        } else {
          par = 4; // Par 4s
          distance = 380 + (index % 5) * 25; // 380-480 yards
        }
        
        return Hole(
          number: holeNumber,
          par: par,
          distance: distance,
          description: 'Hole $holeNumber - Par $par',
        );
      }),
    );
  }

  static CourseModel _createChampionshipCourse() {
    return CourseModel(
      id: 'template_championship',
      name: 'Championship Course',
      location: 'Championship Template',
      slope: 140,
      rating: 74.5,
      createdAt: DateTime.now(),
      holes: List.generate(18, (index) {
        final holeNumber = index + 1;
        int par;
        double distance;
        
        // Championship length holes
        if ([2, 5, 9, 13, 18].contains(holeNumber)) {
          par = 5;
          distance = 580 + (index % 3) * 40; // Longer par 5s
        } else if ([3, 7, 12, 16].contains(holeNumber)) {
          par = 3;
          distance = 180 + (index % 4) * 25; // Longer par 3s
        } else {
          par = 4;
          distance = 420 + (index % 5) * 35; // Longer par 4s
        }
        
        return Hole(
          number: holeNumber,
          par: par,
          distance: distance,
          description: 'Championship Hole $holeNumber - Par $par',
        );
      }),
    );
  }

  static CourseModel _createExecutiveCourse() {
    return CourseModel(
      id: 'template_executive',
      name: 'Executive Course',
      location: 'Executive Template',
      slope: 100,
      rating: 65.0,
      createdAt: DateTime.now(),
      holes: List.generate(18, (index) {
        final holeNumber = index + 1;
        int par;
        double distance;
        
        // Executive course - shorter, more par 3s
        if ([5, 9, 14, 18].contains(holeNumber)) {
          par = 5;
          distance = 480 + (index % 2) * 25; // Shorter par 5s
        } else if (holeNumber % 3 == 0) {
          par = 3;
          distance = 120 + (index % 3) * 15; // Many par 3s
        } else {
          par = 4;
          distance = 300 + (index % 4) * 20; // Shorter par 4s
        }
        
        return Hole(
          number: holeNumber,
          par: par,
          distance: distance,
          description: 'Executive Hole $holeNumber - Par $par',
        );
      }),
    );
  }
}