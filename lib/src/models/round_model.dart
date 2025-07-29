import 'package:cloud_firestore/cloud_firestore.dart';
import 'course_model.dart';
import 'shot_model.dart';

class RoundModel {
  final String id;
  final String userId;
  final String courseId;
  final String courseName;
  final DateTime startTime;
  final DateTime? endTime;
  final RoundStatus status;
  final List<HoleScore> holeScores;
  final List<String> shotIds;
  final Map<String, dynamic> metadata;

  RoundModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.courseName,
    required this.startTime,
    this.endTime,
    this.status = RoundStatus.inProgress,
    this.holeScores = const [],
    this.shotIds = const [],
    this.metadata = const {},
  });

  factory RoundModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoundModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null 
          ? (data['endTime'] as Timestamp).toDate() 
          : null,
      status: RoundStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => RoundStatus.inProgress,
      ),
      holeScores: (data['holeScores'] as List<dynamic>?)
          ?.map((score) => HoleScore.fromMap(score))
          .toList() ?? [],
      shotIds: List<String>.from(data['shotIds'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'courseId': courseId,
      'courseName': courseName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status.name,
      'holeScores': holeScores.map((score) => score.toMap()).toList(),
      'shotIds': shotIds,
      'metadata': metadata,
    };
  }

  // Calculated properties
  int get totalStrokes => holeScores.fold(0, (sum, score) => sum + score.strokes);
  
  int get totalPar => holeScores.fold(0, (sum, score) => sum + score.par);
  
  int get scoreRelativeToPar => totalStrokes - totalPar;
  
  String get scoreDisplay {
    final relative = scoreRelativeToPar;
    if (relative == 0) return 'E ($totalStrokes)';
    if (relative > 0) return '+$relative ($totalStrokes)';
    return '$relative ($totalStrokes)';
  }
  
  double get averageStrokesPerHole {
    if (holeScores.isEmpty) return 0.0;
    return totalStrokes / holeScores.length;
  }
  
  int get holesCompleted => holeScores.where((score) => score.completed).length;
  
  bool get isComplete => status == RoundStatus.completed;
  
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  RoundModel copyWith({
    String? id,
    String? userId,
    String? courseId,
    String? courseName,
    DateTime? startTime,
    DateTime? endTime,
    RoundStatus? status,
    List<HoleScore>? holeScores,
    List<String>? shotIds,
    Map<String, dynamic>? metadata,
  }) {
    return RoundModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      holeScores: holeScores ?? this.holeScores,
      shotIds: shotIds ?? this.shotIds,
      metadata: metadata ?? this.metadata,
    );
  }
}

class HoleScore {
  final int holeNumber;
  final int par;
  final int strokes;
  final bool completed;
  final List<String> shotIds;
  final DateTime? completedAt;
  final Map<String, dynamic> metadata;

  HoleScore({
    required this.holeNumber,
    required this.par,
    this.strokes = 0,
    this.completed = false,
    this.shotIds = const [],
    this.completedAt,
    this.metadata = const {},
  });

  factory HoleScore.fromMap(Map<String, dynamic> map) {
    return HoleScore(
      holeNumber: map['holeNumber'] ?? 1,
      par: map['par'] ?? 4,
      strokes: map['strokes'] ?? 0,
      completed: map['completed'] ?? false,
      shotIds: List<String>.from(map['shotIds'] ?? []),
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'holeNumber': holeNumber,
      'par': par,
      'strokes': strokes,
      'completed': completed,
      'shotIds': shotIds,
      'completedAt': completedAt != null 
          ? Timestamp.fromDate(completedAt!) 
          : null,
      'metadata': metadata,
    };
  }

  int get scoreRelativeToPar => strokes - par;
  
  String get scoreDescription {
    final relative = scoreRelativeToPar;
    if (par == 3) {
      switch (relative) {
        case -2: return 'Eagle';
        case -1: return 'Birdie';
        case 0: return 'Par';
        case 1: return 'Bogey';
        case 2: return 'Double Bogey';
        default: return relative > 2 ? '${relative.abs()}+ Over' : 'Under Par';
      }
    } else if (par == 4) {
      switch (relative) {
        case -3: return 'Albatross';
        case -2: return 'Eagle';
        case -1: return 'Birdie';
        case 0: return 'Par';
        case 1: return 'Bogey';
        case 2: return 'Double Bogey';
        default: return relative > 2 ? '${relative.abs()}+ Over' : 'Under Par';
      }
    } else { // par 5
      switch (relative) {
        case -4: return 'Condor';
        case -3: return 'Albatross';
        case -2: return 'Eagle';
        case -1: return 'Birdie';
        case 0: return 'Par';
        case 1: return 'Bogey';
        case 2: return 'Double Bogey';
        default: return relative > 2 ? '${relative.abs()}+ Over' : 'Under Par';
      }
    }
  }

  HoleScore copyWith({
    int? holeNumber,
    int? par,
    int? strokes,
    bool? completed,
    List<String>? shotIds,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return HoleScore(
      holeNumber: holeNumber ?? this.holeNumber,
      par: par ?? this.par,
      strokes: strokes ?? this.strokes,
      completed: completed ?? this.completed,
      shotIds: shotIds ?? this.shotIds,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum RoundStatus {
  inProgress,
  paused,
  completed,
  abandoned,
}