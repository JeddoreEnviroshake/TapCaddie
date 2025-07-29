import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/nfc_service.dart';
import '../models/course_model.dart';
import '../models/round_model.dart';
import '../models/shot_model.dart';
import '../models/user_model.dart';

class GameProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final LocationService _locationService;
  final NFCService _nfcService;

  // Current game state
  CourseModel? _selectedCourse;
  RoundModel? _currentRound;
  List<ShotModel> _currentRoundShots = [];
  Position? _currentPosition;
  Position? _lastShotPosition;
  
  // Current hole state
  int _currentHole = 1;
  int _currentShotNumber = 1;
  List<ShotModel> _holeShots = [];
  
  // UI state
  bool _isLoading = false;
  bool _isTrackingShots = false;
  String? _errorMessage;
  String? _lastNfcTag;
  
  GameProvider({
    required FirestoreService firestoreService,
    required LocationService locationService,
    required NFCService nfcService,
  })  : _firestoreService = firestoreService,
        _locationService = locationService,
        _nfcService = nfcService {
    _initialize();
  }

  // Getters
  CourseModel? get selectedCourse => _selectedCourse;
  RoundModel? get currentRound => _currentRound;
  List<ShotModel> get currentRoundShots => _currentRoundShots;
  Position? get currentPosition => _currentPosition;
  int get currentHole => _currentHole;
  int get currentShotNumber => _currentShotNumber;
  List<ShotModel> get holeShots => _holeShots;
  bool get isLoading => _isLoading;
  bool get isTrackingShots => _isTrackingShots;
  String? get errorMessage => _errorMessage;
  String? get lastNfcTag => _lastNfcTag;
  bool get isRoundActive => _currentRound != null && !_currentRound!.isComplete;

  // Initialize services
  void _initialize() async {
    await _nfcService.initialize();
    await _getCurrentLocation();
  }

  // Select course for new round
  Future<bool> selectCourse(CourseModel course) async {
    _setLoading(true);
    
    try {
      _selectedCourse = course;
      _clearError();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to select course: $e');
      _setLoading(false);
      return false;
    }
  }

  // Start new round
  Future<bool> startNewRound(String userId) async {
    if (_selectedCourse == null) {
      _setError('No course selected');
      return false;
    }

    _setLoading(true);
    
    try {
      // Create new round
      final round = RoundModel(
        id: '', // Will be set by Firestore
        userId: userId,
        courseId: _selectedCourse!.id,
        courseName: _selectedCourse!.name,
        startTime: DateTime.now(),
        status: RoundStatus.inProgress,
        holeScores: _selectedCourse!.holes.map((hole) => HoleScore(
          holeNumber: hole.number,
          par: hole.par,
        )).toList(),
      );

      final roundId = await _firestoreService.createRound(round);
      _currentRound = round.copyWith(id: roundId);
      
      // Reset game state
      _currentHole = 1;
      _currentShotNumber = 1;
      _currentRoundShots = [];
      _holeShots = [];
      _lastShotPosition = null;

      // Start location and NFC tracking
      await _startShotTracking();
      
      _clearError();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to start round: $e');
      _setLoading(false);
      return false;
    }
  }

  // Resume existing round
  Future<bool> resumeRound(String roundId) async {
    _setLoading(true);
    
    try {
      final round = await _firestoreService.getRound(roundId);
      if (round == null) {
        _setError('Round not found');
        _setLoading(false);
        return false;
      }

      _currentRound = round;
      
      // Load course
      final course = await _firestoreService.getCourse(round.courseId);
      _selectedCourse = course;
      
      // Load shots
      _currentRoundShots = await _firestoreService.getRoundShots(roundId);
      
      // Determine current hole and shot
      _updateCurrentHoleAndShot();
      
      // Start tracking
      await _startShotTracking();
      
      _clearError();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to resume round: $e');
      _setLoading(false);
      return false;
    }
  }

  // Start shot tracking (location and NFC)
  Future<void> _startShotTracking() async {
    if (_isTrackingShots) return;
    
    try {
      _isTrackingShots = true;
      
      // Start location tracking
      _locationService.startLocationTracking(
        onLocationUpdate: (Position position) {
          _currentPosition = position;
          notifyListeners();
        },
        onError: (String error) {
          _setError('Location error: $error');
        },
      );
      
      // Start NFC listening
      await _nfcService.startListening();
      
      // Listen for NFC tags
      _nfcService.nfcTagStream.listen((String tagId) {
        _handleNfcTagRead(tagId);
      });
      
    } catch (e) {
      _setError('Failed to start shot tracking: $e');
    }
  }

  // Stop shot tracking
  Future<void> _stopShotTracking() async {
    _isTrackingShots = false;
    _locationService.stopLocationTracking();
    await _nfcService.stopListening();
  }

  // Handle NFC tag read
  Future<void> _handleNfcTagRead(String tagId) async {
    if (_currentRound == null || _currentPosition == null) return;
    
    _lastNfcTag = tagId;
    
    try {
      // Calculate distance from previous shot (if exists)
      double? distance;
      if (_lastShotPosition != null) {
        final distanceInMeters = _locationService.calculateDistance(
          _lastShotPosition!.latitude,
          _lastShotPosition!.longitude,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        distance = _locationService.metersToYards(distanceInMeters);
        
        // Update previous shot with end position and distance
        await _updateLastShotWithDistance(distance);
      }

      // Create new shot
      await _createShot(tagId, _currentPosition!);
      
      // Update shot position for next distance calculation
      _lastShotPosition = _currentPosition;
      
    } catch (e) {
      _setError('Failed to process shot: $e');
    }
  }

  // Create new shot
  Future<void> _createShot(String nfcTagId, Position position) async {
    if (_currentRound == null) return;
    
    final shot = ShotModel(
      id: '', // Will be set by Firestore
      userId: _currentRound!.userId,
      roundId: _currentRound!.id,
      holeNumber: _currentHole,
      shotNumber: _currentShotNumber,
      clubId: nfcTagId, // Using NFC tag as club ID for now
      clubName: _nfcService.getClubNameFromTagId(nfcTagId),
      startPosition: _locationService.positionToGeoPoint(position),
      timestamp: DateTime.now(),
    );

    try {
      final shotId = await _firestoreService.createShot(shot);
      final createdShot = shot.copyWith(id: shotId);
      
      _currentRoundShots.add(createdShot);
      _holeShots.add(createdShot);
      
      // Increment shot number
      _currentShotNumber++;
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to create shot: $e');
    }
  }

  // Update last shot with end position and distance
  Future<void> _updateLastShotWithDistance(double distance) async {
    if (_currentRoundShots.isEmpty || _currentPosition == null) return;
    
    final lastShot = _currentRoundShots.last;
    final updatedShot = lastShot.copyWith(
      endPosition: _locationService.positionToGeoPoint(_currentPosition!),
      distance: distance,
    );

    try {
      await _firestoreService.updateShot(updatedShot);
      
      // Update local state
      _currentRoundShots[_currentRoundShots.length - 1] = updatedShot;
      if (_holeShots.isNotEmpty) {
        _holeShots[_holeShots.length - 1] = updatedShot;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to update shot distance: $e');
    }
  }

  // Complete current hole
  Future<bool> completeHole(int strokes) async {
    if (_currentRound == null) return false;
    
    try {
      // Update hole score
      final holeScores = List<HoleScore>.from(_currentRound!.holeScores);
      final holeIndex = _currentHole - 1;
      
      if (holeIndex < holeScores.length) {
        holeScores[holeIndex] = holeScores[holeIndex].copyWith(
          strokes: strokes,
          completed: true,
          completedAt: DateTime.now(),
          shotIds: _holeShots.map((shot) => shot.id).toList(),
        );
        
        // Update round
        final updatedRound = _currentRound!.copyWith(
          holeScores: holeScores,
        );
        
        await _firestoreService.updateRound(updatedRound);
        _currentRound = updatedRound;
        
        // Move to next hole or complete round
        if (_currentHole < _selectedCourse!.holes.length) {
          _moveToNextHole();
        } else {
          await _completeRound();
        }
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _setError('Failed to complete hole: $e');
      return false;
    }
  }

  // Move to next hole
  void _moveToNextHole() {
    _currentHole++;
    _currentShotNumber = 1;
    _holeShots = [];
    _lastShotPosition = null;
  }

  // Complete round
  Future<void> _completeRound() async {
    if (_currentRound == null) return;
    
    try {
      final completedRound = _currentRound!.copyWith(
        status: RoundStatus.completed,
        endTime: DateTime.now(),
      );
      
      await _firestoreService.updateRound(completedRound);
      _currentRound = completedRound;
      
      // Stop tracking
      await _stopShotTracking();
      
    } catch (e) {
      _setError('Failed to complete round: $e');
    }
  }

  // Pause round
  Future<bool> pauseRound() async {
    if (_currentRound == null) return false;
    
    try {
      final pausedRound = _currentRound!.copyWith(status: RoundStatus.paused);
      await _firestoreService.updateRound(pausedRound);
      _currentRound = pausedRound;
      
      await _stopShotTracking();
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to pause round: $e');
      return false;
    }
  }

  // Abandon round
  Future<bool> abandonRound() async {
    if (_currentRound == null) return false;
    
    try {
      final abandonedRound = _currentRound!.copyWith(
        status: RoundStatus.abandoned,
        endTime: DateTime.now(),
      );
      await _firestoreService.updateRound(abandonedRound);
      
      await _stopShotTracking();
      _resetGameState();
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to abandon round: $e');
      return false;
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await _locationService.getCurrentLocation();
      notifyListeners();
    } catch (e) {
      _setError('Failed to get location: $e');
    }
  }

  // Update current hole and shot from existing data
  void _updateCurrentHoleAndShot() {
    if (_currentRoundShots.isEmpty) {
      _currentHole = 1;
      _currentShotNumber = 1;
      _holeShots = [];
      return;
    }

    // Find the last incomplete hole
    final lastShot = _currentRoundShots.last;
    _currentHole = lastShot.holeNumber;
    
    // Get shots for current hole
    _holeShots = _currentRoundShots
        .where((shot) => shot.holeNumber == _currentHole)
        .toList();
    
    _currentShotNumber = _holeShots.length + 1;
    
    // Set last shot position for distance calculation
    if (_holeShots.isNotEmpty) {
      _lastShotPosition = Position(
        longitude: _holeShots.last.startPosition.longitude,
        latitude: _holeShots.last.startPosition.latitude,
        timestamp: _holeShots.last.timestamp,
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  // Reset game state
  void _resetGameState() {
    _selectedCourse = null;
    _currentRound = null;
    _currentRoundShots = [];
    _currentHole = 1;
    _currentShotNumber = 1;
    _holeShots = [];
    _lastShotPosition = null;
    _isTrackingShots = false;
  }

  // Simulate NFC tag read (for testing)
  void simulateNfcTag(String tagId) {
    _nfcService.simulateTagRead(tagId);
  }

  // Manual shot entry
  Future<bool> addManualShot({
    required String clubId,
    required String clubName,
    double? distance,
    ShotResult? result,
  }) async {
    if (_currentRound == null || _currentPosition == null) return false;
    
    try {
      final shot = ShotModel(
        id: '',
        userId: _currentRound!.userId,
        roundId: _currentRound!.id,
        holeNumber: _currentHole,
        shotNumber: _currentShotNumber,
        clubId: clubId,
        clubName: clubName,
        startPosition: _locationService.positionToGeoPoint(_currentPosition!),
        distance: distance,
        timestamp: DateTime.now(),
        result: result ?? ShotResult.unknown,
        metadata: {'manual': true},
      );

      final shotId = await _firestoreService.createShot(shot);
      final createdShot = shot.copyWith(id: shotId);
      
      _currentRoundShots.add(createdShot);
      _holeShots.add(createdShot);
      _currentShotNumber++;
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add manual shot: $e');
      return false;
    }
  }

  // Get club recommendations based on distance to green
  List<Club> getClubRecommendations(List<Club> userClubs, double distanceToGreen) {
    // Simple recommendation based on average distances
    final recommendations = <Club>[];
    
    for (final club in userClubs) {
      if (club.averageDistance != null) {
        final difference = (club.averageDistance! - distanceToGreen).abs();
        if (difference <= 20) { // Within 20 yards
          recommendations.add(club);
        }
      }
    }
    
    // Sort by closest average distance to target
    recommendations.sort((a, b) {
      final aDiff = (a.averageDistance! - distanceToGreen).abs();
      final bDiff = (b.averageDistance! - distanceToGreen).abs();
      return aDiff.compareTo(bDiff);
    });
    
    return recommendations.take(3).toList(); // Top 3 recommendations
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _locationService.dispose();
    _nfcService.dispose();
    super.dispose();
  }
}