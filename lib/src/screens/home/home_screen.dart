import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../config/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      final userId = authProvider.userModel!.id;
      context.read<AnalyticsProvider>().loadAnalyticsData(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TapCaddie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: Consumer3<AuthProvider, GameProvider, AnalyticsProvider>(
        builder: (context, authProvider, gameProvider, analyticsProvider, _) {
          final user = authProvider.userModel;
          
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                _buildWelcomeHeader(user.name),
                
                const SizedBox(height: 24),
                
                // Quick Actions
                _buildQuickActions(gameProvider),
                
                const SizedBox(height: 24),
                
                // Current Round Status
                if (gameProvider.isRoundActive)
                  _buildCurrentRoundCard(gameProvider),
                
                const SizedBox(height: 24),
                
                // Recent Activity
                _buildRecentActivity(analyticsProvider),
                
                const SizedBox(height: 24),
                
                // Performance Overview
                _buildPerformanceOverview(analyticsProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(String userName) {
    final timeOfDay = DateTime.now().hour;
    String greeting;
    
    if (timeOfDay < 12) {
      greeting = 'Good Morning';
    } else if (timeOfDay < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: const TextStyle(
                fontSize: 18,
                color: AppTheme.pureWhite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.pureWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ready to improve your game?',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.pureWhite.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(GameProvider gameProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Start Round',
                    Icons.play_arrow,
                    AppTheme.primaryGreen,
                    () => context.go('/course-selection'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Analytics',
                    Icons.analytics,
                    AppTheme.accentGreen,
                    () => context.go('/analytics'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'NFC Test',
                    Icons.nfc,
                    AppTheme.fairwayGreen,
                    () => _showNFCTestDialog(gameProvider),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Settings',
                    Icons.settings,
                    AppTheme.mediumGray,
                    () => context.go('/settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppTheme.pureWhite,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentRoundCard(GameProvider gameProvider) {
    final round = gameProvider.currentRound!;
    final course = gameProvider.selectedCourse;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.golf_course, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Current Round',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              round.courseName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hole ${gameProvider.currentHole}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (course != null && gameProvider.currentHole <= course.holes.length)
                      Text(
                        'Par ${course.holes[gameProvider.currentHole - 1].par}',
                        style: const TextStyle(color: AppTheme.mediumGray),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Shot ${gameProvider.currentShotNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${round.holesCompleted}/18 holes',
                      style: const TextStyle(color: AppTheme.mediumGray),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go('/shot-tracking?roundId=${round.id}&holeNumber=${gameProvider.currentHole}'),
                    child: const Text('Continue Round'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _showPauseRoundDialog(gameProvider),
                  child: const Text('Pause'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(AnalyticsProvider analyticsProvider) {
    final rounds = analyticsProvider.userRounds.take(3).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Rounds',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextButton(
                  onPressed: () => context.go('/analytics'),
                  child: const Text('View All'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (rounds.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.golf_course,
                      size: 48,
                      color: AppTheme.mediumGray,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No rounds played yet',
                      style: TextStyle(color: AppTheme.mediumGray),
                    ),
                  ],
                ),
              )
            else
              ...rounds.map((round) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    '${round.totalStrokes}',
                    style: const TextStyle(
                      color: AppTheme.pureWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(round.courseName),
                subtitle: Text(
                  '${round.startTime.day}/${round.startTime.month}/${round.startTime.year} • ${round.scoreDisplay}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/scorecard?courseId=${round.courseId}'),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview(AnalyticsProvider analyticsProvider) {
    final stats = analyticsProvider.performanceStats;
    
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Performance Overview',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextButton(
                  onPressed: () => context.go('/analytics'),
                  child: const Text('Details'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Avg Score',
                    '${stats.averageScore.toStringAsFixed(1)}',
                    Icons.score,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Best Score',
                    '${stats.bestScore}',
                    Icons.emoji_events,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Fairways',
                    '${(stats.fairwayHitRate * 100).round()}%',
                    Icons.straighten,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Rounds',
                    '${stats.totalRounds}',
                    Icons.golf_course,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  void _showNFCTestDialog(GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('NFC Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Test NFC functionality with simulated tags:'),
            const SizedBox(height: 16),
            ...['driver_001', 'iron_7_001', 'wedge_pw_001', 'putter_001'].map(
              (tagId) => ListTile(
                title: Text(tagId),
                trailing: ElevatedButton(
                  onPressed: () {
                    gameProvider.simulateNfcTag(tagId);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Simulated NFC tag: $tagId'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  },
                  child: const Text('Tap'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPauseRoundDialog(GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Round'),
        content: const Text('Do you want to pause the current round? You can resume it later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await gameProvider.pauseRound();
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Round paused'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            },
            child: const Text('Pause'),
          ),
        ],
      ),
    );
  }
}