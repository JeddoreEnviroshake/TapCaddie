import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/game_provider.dart';
import '../../models/course_model.dart';
import '../../models/round_model.dart';
import '../../config/app_theme.dart';

class ScorecardScreen extends StatefulWidget {
  final String courseId;
  
  const ScorecardScreen({super.key, required this.courseId});

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scorecard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(),
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, _) {
          final round = gameProvider.currentRound;
          final course = gameProvider.selectedCourse;
          
          if (round == null || course == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppTheme.mediumGray),
                  SizedBox(height: 16),
                  Text('No active round found'),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Round Header
              _buildRoundHeader(round, course),
              
              // Scorecard Table
              Expanded(
                child: _buildScorecardTable(round, course, gameProvider),
              ),
              
              // Action Buttons
              _buildActionButtons(round, gameProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoundHeader(RoundModel round, CourseModel course) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              round.courseName,
              style: const TextStyle(
                fontSize: 20,
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
                      'Started: ${_formatTime(round.startTime)}',
                      style: const TextStyle(color: AppTheme.mediumGray),
                    ),
                    Text(
                      'Status: ${round.status.name.toUpperCase()}',
                      style: TextStyle(
                        color: _getStatusColor(round.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Score: ${round.scoreDisplay}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    Text(
                      '${round.holesCompleted}/${course.holes.length} holes',
                      style: const TextStyle(color: AppTheme.mediumGray),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorecardTable(RoundModel round, CourseModel course, GameProvider gameProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: MaterialStateColor.resolveWith(
              (states) => AppTheme.primaryGreen.withOpacity(0.1),
            ),
            columns: const [
              DataColumn(
                label: Text(
                  'Hole',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Par',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Yards',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Score',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'To Par',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Shots',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: course.holes.map((hole) {
              final holeScore = round.holeScores.firstWhere(
                (score) => score.holeNumber == hole.number,
                orElse: () => HoleScore(
                  holeNumber: hole.number,
                  par: hole.par,
                ),
              );
              
              final isCurrentHole = gameProvider.currentHole == hole.number;
              
              return DataRow(
                color: MaterialStateColor.resolveWith((states) {
                  if (isCurrentHole) {
                    return AppTheme.accentGreen.withOpacity(0.1);
                  }
                  return Colors.transparent;
                }),
                cells: [
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCurrentHole ? AppTheme.primaryGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${hole.number}',
                        style: TextStyle(
                          color: isCurrentHole ? AppTheme.pureWhite : null,
                          fontWeight: isCurrentHole ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text('${hole.par}')),
                  DataCell(Text('${hole.distance.round()}')),
                  DataCell(
                    holeScore.completed
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getScoreColor(holeScore.scoreRelativeToPar),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${holeScore.strokes}',
                              style: const TextStyle(
                                color: AppTheme.pureWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const Text('-'),
                  ),
                  DataCell(
                    holeScore.completed
                        ? Text(
                            _formatScoreToPar(holeScore.scoreRelativeToPar),
                            style: TextStyle(
                              color: _getScoreColor(holeScore.scoreRelativeToPar),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const Text('-'),
                  ),
                  DataCell(
                    holeScore.completed
                        ? Text('${holeScore.shotIds.length}')
                        : isCurrentHole
                            ? Text('${gameProvider.holeShots.length}')
                            : const Text('-'),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(RoundModel round, GameProvider gameProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Primary Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: gameProvider.isRoundActive
                  ? () => context.go('/shot-tracking?roundId=${round.id}&holeNumber=${gameProvider.currentHole}')
                  : null,
              icon: const Icon(Icons.golf_course),
              label: Text(
                gameProvider.isRoundActive
                    ? 'Continue Playing (Hole ${gameProvider.currentHole})'
                    : 'Round Complete',
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Secondary Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showManualScoreDialog(gameProvider),
                  icon: const Icon(Icons.edit),
                  label: const Text('Manual Score'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/analytics'),
                  icon: const Icon(Icons.analytics),
                  label: const Text('View Stats'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(RoundStatus status) {
    switch (status) {
      case RoundStatus.inProgress:
        return AppTheme.successGreen;
      case RoundStatus.paused:
        return AppTheme.warningOrange;
      case RoundStatus.completed:
        return AppTheme.primaryGreen;
      case RoundStatus.abandoned:
        return AppTheme.errorRed;
    }
  }

  Color _getScoreColor(int scoreToPar) {
    if (scoreToPar <= -2) return Colors.purple;      // Eagle or better
    if (scoreToPar == -1) return Colors.red;        // Birdie
    if (scoreToPar == 0) return AppTheme.primaryGreen; // Par
    if (scoreToPar == 1) return AppTheme.warningOrange; // Bogey
    return AppTheme.errorRed;                        // Double bogey or worse
  }

  String _formatScoreToPar(int scoreToPar) {
    if (scoreToPar == 0) return 'E';
    if (scoreToPar > 0) return '+$scoreToPar';
    return '$scoreToPar';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.pause),
            title: const Text('Pause Round'),
            onTap: () {
              Navigator.pop(context);
              _showPauseRoundDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.stop, color: AppTheme.errorRed),
            title: const Text('Abandon Round', style: TextStyle(color: AppTheme.errorRed)),
            onTap: () {
              Navigator.pop(context);
              _showAbandonRoundDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Scorecard'),
            onTap: () {
              Navigator.pop(context);
              _shareScorecard();
            },
          ),
        ],
      ),
    );
  }

  void _showPauseRoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Round'),
        content: const Text('Do you want to pause the current round? You can resume it later from the home screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final gameProvider = context.read<GameProvider>();
              final success = await gameProvider.pauseRound();
              
              if (success && mounted) {
                context.go('/home');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Round paused successfully'),
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

  void _showAbandonRoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon Round'),
        content: const Text('Are you sure you want to abandon this round? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(context);
              final gameProvider = context.read<GameProvider>();
              final success = await gameProvider.abandonRound();
              
              if (success && mounted) {
                context.go('/home');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Round abandoned'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
              }
            },
            child: const Text('Abandon'),
          ),
        ],
      ),
    );
  }

  void _showManualScoreDialog(GameProvider gameProvider) {
    final holeController = TextEditingController();
    final strokesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Score Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: holeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hole Number',
                prefixIcon: Icon(Icons.golf_course),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: strokesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of Strokes',
                prefixIcon: Icon(Icons.sports_golf),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final hole = int.tryParse(holeController.text);
              final strokes = int.tryParse(strokesController.text);
              
              if (hole != null && strokes != null && strokes > 0) {
                Navigator.pop(context);
                _updateHoleScore(gameProvider, hole, strokes);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateHoleScore(GameProvider gameProvider, int hole, int strokes) async {
    final success = await gameProvider.completeHole(strokes);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hole $hole score updated: $strokes strokes'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gameProvider.errorMessage ?? 'Failed to update score'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _shareScorecard() {
    // TODO: Implement scorecard sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scorecard sharing coming soon!'),
        backgroundColor: AppTheme.warningOrange,
      ),
    );
  }
}