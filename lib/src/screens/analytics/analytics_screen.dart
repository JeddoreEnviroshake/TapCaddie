import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAnalytics() {
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
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Clubs', icon: Icon(Icons.golf_course)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, analyticsProvider, _) {
          if (analyticsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (analyticsProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading analytics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(analyticsProvider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAnalytics,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(analyticsProvider),
              _buildClubsTab(analyticsProvider),
              _buildTrendsTab(analyticsProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(AnalyticsProvider analyticsProvider) {
    final stats = analyticsProvider.performanceStats;
    final insights = analyticsProvider.getPerformanceInsights();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Stats
          if (stats != null) ...[
            _buildPerformanceStatsCard(stats),
            const SizedBox(height: 16),
          ],
          
          // Insights
          if (insights.isNotEmpty) ...[
            _buildInsightsCard(insights),
            const SizedBox(height: 16),
          ],
          
          // Recent Rounds Summary
          _buildRecentRoundsCard(analyticsProvider),
          
          const SizedBox(height: 16),
          
          // Quick Stats
          _buildQuickStatsGrid(analyticsProvider),
        ],
      ),
    );
  }

  Widget _buildClubsTab(AnalyticsProvider analyticsProvider) {
    final clubAnalytics = analyticsProvider.clubAnalytics;

    if (clubAnalytics.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.golf_course,
              size: 64,
              color: AppTheme.mediumGray,
            ),
            SizedBox(height: 16),
            Text(
              'No club data available',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.mediumGray,
              ),
            ),
            Text(
              'Start playing rounds to see club analytics',
              style: TextStyle(color: AppTheme.mediumGray),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clubAnalytics.length,
      itemBuilder: (context, index) {
        final clubId = clubAnalytics.keys.elementAt(index);
        final analytics = clubAnalytics[clubId]!;
        return _buildClubAnalyticsCard(analytics);
      },
    );
  }

  Widget _buildTrendsTab(AnalyticsProvider analyticsProvider) {
    final trends = analyticsProvider.roundTrends;

    if (trends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: AppTheme.mediumGray,
            ),
            SizedBox(height: 16),
            Text(
              'No trend data available',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.mediumGray,
              ),
            ),
            Text(
              'Play more rounds to see performance trends',
              style: TextStyle(color: AppTheme.mediumGray),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildScoreTrendChart(trends),
          const SizedBox(height: 16),
          _buildRoundsPerMonthChart(trends),
        ],
      ),
    );
  }

  Widget _buildPerformanceStatsCard(PerformanceStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Average Score',
                    '${stats.averageScore.toStringAsFixed(1)}',
                    Icons.score,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Best Score',
                    '${stats.bestScore}',
                    Icons.emoji_events,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Fairway Hit %',
                    '${(stats.fairwayHitRate * 100).round()}%',
                    Icons.straighten,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'GIR %',
                    '${(stats.greenInRegulationRate * 100).round()}%',
                    Icons.flag,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(List<String> insights) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: AppTheme.accentGreen),
                const SizedBox(width: 8),
                Text(
                  'Performance Insights',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppTheme.primaryGreen)),
                  Expanded(child: Text(insight)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRoundsCard(AnalyticsProvider analyticsProvider) {
    final recentRounds = analyticsProvider.userRounds.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Rounds',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            if (recentRounds.isEmpty)
              const Center(
                child: Text(
                  'No rounds played yet',
                  style: TextStyle(color: AppTheme.mediumGray),
                ),
              )
            else
              ...recentRounds.map((round) => ListTile(
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
                  '${round.startTime.day}/${round.startTime.month}/${round.startTime.year}',
                ),
                trailing: Text(
                  round.scoreDisplay,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid(AnalyticsProvider analyticsProvider) {
    final totalShots = analyticsProvider.userShots.length;
    final totalRounds = analyticsProvider.userRounds.length;
    final totalClubs = analyticsProvider.clubAnalytics.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Shots',
                    '$totalShots',
                    Icons.sports_golf,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Rounds Played',
                    '$totalRounds',
                    Icons.golf_course,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Clubs Used',
                    '$totalClubs',
                    Icons.inventory,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubAnalyticsCard(ClubAnalytics analytics) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                  analytics.clubName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Shots',
                    '${analytics.totalShots}',
                    Icons.sports_golf,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Avg Distance',
                    '${analytics.averageDistance.round()} yds',
                    Icons.straighten,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Max Distance',
                    '${analytics.maxDistance.round()} yds',
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Fairway %',
                    '${(analytics.fairwayHitRate * 100).round()}%',
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreTrendChart(List<RoundTrend> trends) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score Trends',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < trends.length) {
                            return Text(
                              trends[index].period.split('-')[1], // Show month
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trends.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.averageScore,
                        );
                      }).toList(),
                      isCurved: true,
                      color: AppTheme.primaryGreen,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundsPerMonthChart(List<RoundTrend> trends) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rounds Per Month',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < trends.length) {
                            return Text(
                              trends[index].period.split('-')[1], // Show month
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: trends.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.roundsPlayed.toDouble(),
                          color: AppTheme.accentGreen,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}