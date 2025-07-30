import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../models/shot_model.dart';
import '../models/round_model.dart';
import '../models/user_model.dart';

class AnalyticsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  // Analytics data
  List<ShotModel> _userShots = [];
  List<RoundModel> _userRounds = [];
  Map<String, ClubAnalytics> _clubAnalytics = {};
  PerformanceStats? _performanceStats;
  List<RoundTrend> _roundTrends = [];
  
  // UI state
  bool _isLoading = false;
  String? _errorMessage;

  AnalyticsProvider({
    required FirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  // Getters
  List<ShotModel> get userShots => _userShots;
  List<RoundModel> get userRounds => _userRounds;
  Map<String, ClubAnalytics> get clubAnalytics => _clubAnalytics;
  PerformanceStats? get performanceStats => _performanceStats;
  List<RoundTrend> get roundTrends => _roundTrends;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load analytics data for user
  Future<void> loadAnalyticsData(String userId) async {
    _setLoading(true);
    
    try {
      // Load shots and rounds in parallel
      final results = await Future.wait([
        _firestoreService.getUserShots(userId),
        _firestoreService.getUserRounds(userId),
      ]);
      
      _userShots = results[0] as List<ShotModel>;
      _userRounds = results[1] as List<RoundModel>;
      
      // Calculate analytics
      _calculateClubAnalytics();
      _calculatePerformanceStats();
      _calculateRoundTrends();
      
      _clearError();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load analytics data: $e');
      _setLoading(false);
    }
  }

  // Calculate club-specific analytics
  void _calculateClubAnalytics() {
    _clubAnalytics.clear();
    
    // Group shots by club
    final clubShotsMap = <String, List<ShotModel>>{};
    for (final shot in _userShots) {
      if (!clubShotsMap.containsKey(shot.clubId)) {
        clubShotsMap[shot.clubId] = [];
      }
      clubShotsMap[shot.clubId]!.add(shot);
    }
    
    // Calculate analytics for each club
    clubShotsMap.forEach((clubId, shots) {
      _clubAnalytics[clubId] = _calculateClubAnalyticsForShots(shots);
    });
  }

  // Calculate analytics for a specific club
  ClubAnalytics _calculateClubAnalyticsForShots(List<ShotModel> shots) {
    if (shots.isEmpty) {
      return ClubAnalytics(
        clubId: shots.first.clubId,
        clubName: shots.first.clubName,
        totalShots: 0,
        averageDistance: 0.0,
        maxDistance: 0.0,
        minDistance: 0.0,
        fairwayHitRate: 0.0,
        greenInRegulationRate: 0.0,
        distances: [],
      );
    }
    
    final distances = shots
        .where((shot) => shot.distance != null && shot.distance! > 0)
        .map((shot) => shot.distance!)
        .toList();
    
    final fairwayHits = shots.where((shot) => shot.result == ShotResult.fairway).length;
    final greenHits = shots.where((shot) => shot.result == ShotResult.green).length;
    
    return ClubAnalytics(
      clubId: shots.first.clubId,
      clubName: shots.first.clubName,
      totalShots: shots.length,
      averageDistance: distances.isNotEmpty ? distances.reduce((a, b) => a + b) / distances.length : 0.0,
      maxDistance: distances.isNotEmpty ? distances.reduce((a, b) => a > b ? a : b) : 0.0,
      minDistance: distances.isNotEmpty ? distances.reduce((a, b) => a < b ? a : b) : 0.0,
      fairwayHitRate: shots.isNotEmpty ? fairwayHits / shots.length : 0.0,
      greenInRegulationRate: shots.isNotEmpty ? greenHits / shots.length : 0.0,
      distances: distances,
    );
  }

  // Calculate overall performance statistics
  void _calculatePerformanceStats() {
    if (_userRounds.isEmpty) {
      _performanceStats = null;
      return;
    }
    
    final completedRounds = _userRounds.where((round) => round.isComplete).toList();
    if (completedRounds.isEmpty) {
      _performanceStats = null;
      return;
    }
    
    final scores = completedRounds.map((round) => round.totalStrokes).toList();
    final pars = completedRounds.map((round) => round.totalPar).toList();
    final scoresToPar = completedRounds.map((round) => round.scoreRelativeToPar).toList();
    
    // Calculate fairway hit percentage
    final fairwayShots = _userShots.where((shot) => 
      shot.result == ShotResult.fairway || 
      shot.result == ShotResult.rough ||
      shot.result == ShotResult.hazard ||
      shot.result == ShotResult.outOfBounds
    ).toList();
    
    final fairwayHits = _userShots.where((shot) => shot.result == ShotResult.fairway).length;
    final fairwayHitRate =
        fairwayShots.isNotEmpty ? fairwayHits / fairwayShots.length : 0.0;
    
    // Calculate GIR (Green in Regulation) percentage
    final girShots = _userShots.where((shot) => shot.result == ShotResult.green).length;
    final totalApproachShots = _userShots.where((shot) => 
      shot.shotNumber <= 2 // Approximate approach shots
    ).length;
    final girRate = totalApproachShots > 0 ? girShots / totalApproachShots : 0.0;
    
    _performanceStats = PerformanceStats(
      totalRounds: completedRounds.length,
      averageScore: scores.reduce((a, b) => a + b) / scores.length,
      bestScore: scores.reduce((a, b) => a < b ? a : b),
      worstScore: scores.reduce((a, b) => a > b ? a : b),
      averageScoreToPar: scoresToPar.reduce((a, b) => a + b) / scoresToPar.length,
      fairwayHitRate: fairwayHitRate.toDouble(),
      greenInRegulationRate: girRate.toDouble(),
      totalShots: _userShots.length,
      averageStrokesPerRound: _userShots.length / completedRounds.length,
    );
  }

  // Calculate round trends over time
  void _calculateRoundTrends() {
    _roundTrends.clear();
    
    final completedRounds = _userRounds
        .where((round) => round.isComplete)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    if (completedRounds.isEmpty) return;
    
    // Group rounds by month
    final monthlyRounds = <String, List<RoundModel>>{};
    for (final round in completedRounds) {
      final monthKey = '${round.startTime.year}-${round.startTime.month.toString().padLeft(2, '0')}';
      if (!monthlyRounds.containsKey(monthKey)) {
        monthlyRounds[monthKey] = [];
      }
      monthlyRounds[monthKey]!.add(round);
    }
    
    // Calculate trends for each month
    monthlyRounds.forEach((monthKey, rounds) {
      final averageScore = rounds.map((r) => r.totalStrokes).reduce((a, b) => a + b) / rounds.length;
      final averageToPar = rounds.map((r) => r.scoreRelativeToPar).reduce((a, b) => a + b) / rounds.length;
      
      _roundTrends.add(RoundTrend(
        period: monthKey,
        roundsPlayed: rounds.length,
        averageScore: averageScore,
        averageScoreToPar: averageToPar,
        bestScore: rounds.map((r) => r.totalStrokes).reduce((a, b) => a < b ? a : b),
      ));
    });
    
    // Sort by period
    _roundTrends.sort((a, b) => a.period.compareTo(b.period));
  }

  // Get club recommendation based on distance
  List<ClubRecommendation> getClubRecommendations(double targetDistance) {
    final recommendations = <ClubRecommendation>[];
    
    _clubAnalytics.forEach((clubId, analytics) {
      if (analytics.averageDistance > 0) {
        final distanceDiff = (analytics.averageDistance - targetDistance).abs();
        final confidence = _calculateConfidence(analytics, targetDistance);
        
        recommendations.add(ClubRecommendation(
          clubId: clubId,
          clubName: analytics.clubName,
          confidence: confidence,
          expectedDistance: analytics.averageDistance,
          distanceDifference: distanceDiff,
        ));
      }
    });
    
    // Sort by confidence (highest first)
    recommendations.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return recommendations.take(3).toList(); // Top 3 recommendations
  }

  // Calculate confidence score for club recommendation
  double _calculateConfidence(ClubAnalytics analytics, double targetDistance) {
    if (analytics.totalShots < 5) return 0.0; // Need minimum shots for confidence
    
    final distanceDiff = (analytics.averageDistance - targetDistance).abs();
    final maxAcceptableDiff = 30.0; // 30 yards
    
    if (distanceDiff > maxAcceptableDiff) return 0.0;
    
    // Base confidence on distance accuracy and shot count
    final distanceScore = 1.0 - (distanceDiff / maxAcceptableDiff);
    final sampleSizeScore = (analytics.totalShots / 20.0).clamp(0.0, 1.0); // Max at 20 shots
    
    return (distanceScore * 0.7 + sampleSizeScore * 0.3).clamp(0.0, 1.0);
  }

  // Get performance insights
  List<String> getPerformanceInsights() {
    final insights = <String>[];
    
    if (_performanceStats == null) return insights;
    
    // Score insights
    if (_performanceStats!.averageScoreToPar > 0) {
      insights.add('You average ${_performanceStats!.averageScoreToPar.toStringAsFixed(1)} over par');
    } else {
      insights.add('You average ${_performanceStats!.averageScoreToPar.abs().toStringAsFixed(1)} under par');
    }
    
    // Fairway insights
    final fairwayPercentage = (_performanceStats!.fairwayHitRate * 100).round();
    if (fairwayPercentage < 50) {
      insights.add('Focus on accuracy - you hit $fairwayPercentage% of fairways');
    } else {
      insights.add('Good fairway accuracy at $fairwayPercentage%');
    }
    
    // GIR insights
    final girPercentage = (_performanceStats!.greenInRegulationRate * 100).round();
    if (girPercentage < 30) {
      insights.add('Work on approach shots - $girPercentage% GIR');
    } else {
      insights.add('Solid approach play with $girPercentage% GIR');
    }
    
    // Club usage insights
    if (_clubAnalytics.isNotEmpty) {
      final mostUsedClub = _clubAnalytics.values
          .reduce((a, b) => a.totalShots > b.totalShots ? a : b);
      insights.add('Most used club: ${mostUsedClub.clubName}');
    }
    
    return insights;
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
}

// Analytics data classes
class ClubAnalytics {
  final String clubId;
  final String clubName;
  final int totalShots;
  final double averageDistance;
  final double maxDistance;
  final double minDistance;
  final double fairwayHitRate;
  final double greenInRegulationRate;
  final List<double> distances;

  ClubAnalytics({
    required this.clubId,
    required this.clubName,
    required this.totalShots,
    required this.averageDistance,
    required this.maxDistance,
    required this.minDistance,
    required this.fairwayHitRate,
    required this.greenInRegulationRate,
    required this.distances,
  });
}

class PerformanceStats {
  final int totalRounds;
  final double averageScore;
  final int bestScore;
  final int worstScore;
  final double averageScoreToPar;
  final double fairwayHitRate;
  final double greenInRegulationRate;
  final int totalShots;
  final double averageStrokesPerRound;

  PerformanceStats({
    required this.totalRounds,
    required this.averageScore,
    required this.bestScore,
    required this.worstScore,
    required this.averageScoreToPar,
    required this.fairwayHitRate,
    required this.greenInRegulationRate,
    required this.totalShots,
    required this.averageStrokesPerRound,
  });
}

class RoundTrend {
  final String period;
  final int roundsPlayed;
  final double averageScore;
  final double averageScoreToPar;
  final int bestScore;

  RoundTrend({
    required this.period,
    required this.roundsPlayed,
    required this.averageScore,
    required this.averageScoreToPar,
    required this.bestScore,
  });
}

class ClubRecommendation {
  final String clubId;
  final String clubName;
  final double confidence;
  final double expectedDistance;
  final double distanceDifference;

  ClubRecommendation({
    required this.clubId,
    required this.clubName,
    required this.confidence,
    required this.expectedDistance,
    required this.distanceDifference,
  });
}