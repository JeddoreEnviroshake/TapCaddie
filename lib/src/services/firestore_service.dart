import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/round_model.dart';
import '../models/shot_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String usersCollection = 'users';
  static const String coursesCollection = 'courses';
  static const String roundsCollection = 'rounds';
  static const String shotsCollection = 'shots';

  // User Operations
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection(usersCollection).doc(user.id).set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection(usersCollection).doc(user.id).update(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Stream<UserModel?> watchUser(String userId) {
    return _firestore.collection(usersCollection).doc(userId).snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Course Operations
  Future<void> createCourse(CourseModel course) async {
    try {
      await _firestore.collection(coursesCollection).doc(course.id).set(course.toFirestore());
    } catch (e) {
      throw Exception('Failed to create course: $e');
    }
  }

  Future<CourseModel?> getCourse(String courseId) async {
    try {
      final doc = await _firestore.collection(coursesCollection).doc(courseId).get();
      if (doc.exists) {
        return CourseModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get course: $e');
    }
  }

  Future<List<CourseModel>> getCourses({int limit = 20}) async {
    try {
      final query = await _firestore
          .collection(coursesCollection)
          .orderBy('name')
          .limit(limit)
          .get();
      
      return query.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get courses: $e');
    }
  }

  Stream<List<CourseModel>> watchCourses({int limit = 20}) {
    return _firestore
        .collection(coursesCollection)
        .orderBy('name')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList());
  }

  // Round Operations
  Future<String> createRound(RoundModel round) async {
    try {
      final docRef = await _firestore.collection(roundsCollection).add(round.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create round: $e');
    }
  }

  Future<RoundModel?> getRound(String roundId) async {
    try {
      final doc = await _firestore.collection(roundsCollection).doc(roundId).get();
      if (doc.exists) {
        return RoundModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get round: $e');
    }
  }

  Future<void> updateRound(RoundModel round) async {
    try {
      await _firestore.collection(roundsCollection).doc(round.id).update(round.toFirestore());
    } catch (e) {
      throw Exception('Failed to update round: $e');
    }
  }

  Future<List<RoundModel>> getUserRounds(String userId, {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection(roundsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();
      
      return query.docs.map((doc) => RoundModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get user rounds: $e');
    }
  }

  Stream<List<RoundModel>> watchUserRounds(String userId, {int limit = 50}) {
    return _firestore
        .collection(roundsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RoundModel.fromFirestore(doc)).toList());
  }

  Future<RoundModel?> getActiveRound(String userId) async {
    try {
      final query = await _firestore
          .collection(roundsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: RoundStatus.inProgress.name)
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return RoundModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get active round: $e');
    }
  }

  // Shot Operations
  Future<String> createShot(ShotModel shot) async {
    try {
      final docRef = await _firestore.collection(shotsCollection).add(shot.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create shot: $e');
    }
  }

  Future<ShotModel?> getShot(String shotId) async {
    try {
      final doc = await _firestore.collection(shotsCollection).doc(shotId).get();
      if (doc.exists) {
        return ShotModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get shot: $e');
    }
  }

  Future<void> updateShot(ShotModel shot) async {
    try {
      await _firestore.collection(shotsCollection).doc(shot.id).update(shot.toFirestore());
    } catch (e) {
      throw Exception('Failed to update shot: $e');
    }
  }

  Future<List<ShotModel>> getRoundShots(String roundId) async {
    try {
      final query = await _firestore
          .collection(shotsCollection)
          .where('roundId', isEqualTo: roundId)
          .orderBy('holeNumber')
          .orderBy('shotNumber')
          .get();
      
      return query.docs.map((doc) => ShotModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get round shots: $e');
    }
  }

  Future<List<ShotModel>> getHoleShots(String roundId, int holeNumber) async {
    try {
      final query = await _firestore
          .collection(shotsCollection)
          .where('roundId', isEqualTo: roundId)
          .where('holeNumber', isEqualTo: holeNumber)
          .orderBy('shotNumber')
          .get();
      
      return query.docs.map((doc) => ShotModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get hole shots: $e');
    }
  }

  Stream<List<ShotModel>> watchRoundShots(String roundId) {
    return _firestore
        .collection(shotsCollection)
        .where('roundId', isEqualTo: roundId)
        .orderBy('holeNumber')
        .orderBy('shotNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ShotModel.fromFirestore(doc)).toList());
  }

  // Analytics Operations
  Future<List<ShotModel>> getUserShots(String userId, {int limit = 500}) async {
    try {
      final query = await _firestore
          .collection(shotsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return query.docs.map((doc) => ShotModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get user shots: $e');
    }
  }

  Future<List<ShotModel>> getClubShots(String userId, String clubId, {int limit = 100}) async {
    try {
      final query = await _firestore
          .collection(shotsCollection)
          .where('userId', isEqualTo: userId)
          .where('clubId', isEqualTo: clubId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return query.docs.map((doc) => ShotModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get club shots: $e');
    }
  }

  // Batch Operations
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firestore.batch();
      
      for (final operation in operations) {
        final type = operation['type'] as String;
        final collection = operation['collection'] as String;
        final data = operation['data'] as Map<String, dynamic>;
        final docId = operation['docId'] as String?;
        
        if (type == 'create') {
          if (docId != null) {
            batch.set(_firestore.collection(collection).doc(docId), data);
          } else {
            batch.set(_firestore.collection(collection).doc(), data);
          }
        } else if (type == 'update') {
          batch.update(_firestore.collection(collection).doc(docId!), data);
        } else if (type == 'delete') {
          batch.delete(_firestore.collection(collection).doc(docId!));
        }
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to execute batch operation: $e');
    }
  }

  // Utility Methods
  Future<bool> documentExists(String collection, String docId) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<int> getCollectionCount(String collection) async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      return snapshot.size;
    } catch (e) {
      return 0;
    }
  }
}