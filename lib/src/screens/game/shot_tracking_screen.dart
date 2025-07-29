import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/shot_model.dart';

class ShotTrackingScreen extends StatefulWidget {
  final String roundId;
  final int holeNumber;
  
  const ShotTrackingScreen({
    super.key,
    required this.roundId,
    required this.holeNumber,
  });

  @override
  State<ShotTrackingScreen> createState() => _ShotTrackingScreenState();
}

class _ShotTrackingScreenState extends State<ShotTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hole ${widget.holeNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: Consumer2<GameProvider, AuthProvider>(
        builder: (context, gameProvider, authProvider, _) {
          final round = gameProvider.currentRound;
          final course = gameProvider.selectedCourse;
          final user = authProvider.userModel;
          
          if (round == null || course == null || user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentHole = course.holes.firstWhere(
            (hole) => hole.number == widget.holeNumber,
          );

          return Column(
            children: [
              // Hole Information
              _buildHoleInfo(currentHole, gameProvider),
              
              // Shot Tracking Area
              Expanded(
                child: _buildShotTrackingArea(gameProvider, user),
              ),
              
              // Action Buttons
              _buildActionButtons(gameProvider, currentHole),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHoleInfo(hole, GameProvider gameProvider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hole ${hole.number}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Par ${hole.par} • ${hole.distance.round()} yards',
                      style: const TextStyle(
                        color: AppTheme.mediumGray,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Shot ${gameProvider.currentShotNumber}',
                    style: const TextStyle(
                      color: AppTheme.pureWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            if (hole.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                hole.description,
                style: const TextStyle(
                  color: AppTheme.mediumGray,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            // Location status
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  gameProvider.currentPosition != null
                      ? Icons.location_on
                      : Icons.location_off,
                  color: gameProvider.currentPosition != null
                      ? AppTheme.successGreen
                      : AppTheme.errorRed,
                ),
                const SizedBox(width: 8),
                Text(
                  gameProvider.currentPosition != null
                      ? 'GPS Ready'
                      : 'Waiting for GPS...',
                  style: TextStyle(
                    color: gameProvider.currentPosition != null
                        ? AppTheme.successGreen
                        : AppTheme.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShotTrackingArea(GameProvider gameProvider, UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // NFC Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        gameProvider.isTrackingShots ? Icons.nfc : Icons.nfc_sharp,
                        color: gameProvider.isTrackingShots 
                            ? AppTheme.successGreen 
                            : AppTheme.mediumGray,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gameProvider.isTrackingShots 
                                  ? 'Ready for NFC Tap'
                                  : 'NFC Not Active',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              gameProvider.isTrackingShots 
                                  ? 'Tap your club to record the shot'
                                  : 'Start tracking to enable NFC',
                              style: const TextStyle(color: AppTheme.mediumGray),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (gameProvider.lastNfcTag != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.golf_course, color: AppTheme.accentGreen),
                          const SizedBox(width: 8),
                          Text(
                            'Last club: ${gameProvider.lastNfcTag}',
                            style: const TextStyle(
                              color: AppTheme.accentGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Current Hole Shots
          Expanded(
            child: Card(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.sports_golf, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          'Shots This Hole (${gameProvider.holeShots.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: gameProvider.holeShots.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sports_golf,
                                  size: 48,
                                  color: AppTheme.mediumGray,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No shots recorded yet',
                                  style: TextStyle(color: AppTheme.mediumGray),
                                ),
                                Text(
                                  'Tap your club to start',
                                  style: TextStyle(
                                    color: AppTheme.mediumGray,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: gameProvider.holeShots.length,
                            itemBuilder: (context, index) {
                              final shot = gameProvider.holeShots[index];
                              return _buildShotItem(shot, index + 1);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Club Recommendations
          if (user.clubs.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.recommend, color: AppTheme.accentGreen),
                        SizedBox(width: 8),
                        Text(
                          'Club Recommendations',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: user.clubs.length,
                        itemBuilder: (context, index) {
                          final club = user.clubs[index];
                          return _buildClubRecommendationCard(club);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShotItem(ShotModel shot, int shotNumber) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryGreen,
        child: Text(
          '$shotNumber',
          style: const TextStyle(
            color: AppTheme.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(shot.clubName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Time: ${_formatTime(shot.timestamp)}'),
          if (shot.hasDistance)
            Text('Distance: ${shot.distanceDisplay}'),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: shot.result.displayName == 'Unknown' 
              ? AppTheme.mediumGray 
              : AppTheme.accentGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          shot.result.emoji,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildClubRecommendationCard(Club club) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getClubIcon(club.type),
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                club.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (club.averageDistance != null)
                Text(
                  '${club.averageDistance!.round()} yds',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.mediumGray,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(GameProvider gameProvider, hole) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Complete Hole Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: gameProvider.holeShots.isNotEmpty
                  ? () => _showCompleteHoleDialog(gameProvider, hole)
                  : null,
              icon: const Icon(Icons.flag),
              label: Text('Complete Hole ${widget.holeNumber}'),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Secondary Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showManualShotDialog(gameProvider),
                  icon: const Icon(Icons.add),
                  label: const Text('Manual Shot'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showNFCTestDialog(gameProvider),
                  icon: const Icon(Icons.nfc),
                  label: const Text('Test NFC'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getClubIcon(ClubType type) {
    switch (type) {
      case ClubType.driver:
        return Icons.sports_golf;
      case ClubType.wood:
        return Icons.forest;
      case ClubType.hybrid:
        return Icons.merge_type;
      case ClubType.iron:
        return Icons.straighten;
      case ClubType.wedge:
        return Icons.change_history;
      case ClubType.putter:
        return Icons.flag;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  void _showCompleteHoleDialog(GameProvider gameProvider, hole) {
    final strokesController = TextEditingController(
      text: '${gameProvider.holeShots.length}',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete Hole ${hole.number}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Par: ${hole.par}'),
            Text('Shots recorded: ${gameProvider.holeShots.length}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: strokesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Strokes',
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
            onPressed: () async {
              final strokes = int.tryParse(strokesController.text);
              if (strokes != null && strokes > 0) {
                Navigator.pop(context);
                
                final success = await gameProvider.completeHole(strokes);
                
                if (success && mounted) {
                  if (gameProvider.currentHole <= 18) {
                    // Move to next hole or scorecard
                    context.go('/scorecard?courseId=${gameProvider.selectedCourse!.id}');
                  } else {
                    // Round complete
                    context.go('/analytics');
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hole ${hole.number} completed with $strokes strokes'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                }
              }
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _showManualShotDialog(GameProvider gameProvider) {
    final clubController = TextEditingController();
    final distanceController = TextEditingController();
    ShotResult selectedResult = ShotResult.unknown;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Manual Shot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: clubController,
                decoration: const InputDecoration(
                  labelText: 'Club Name',
                  prefixIcon: Icon(Icons.golf_course),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: distanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Distance (yards)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ShotResult>(
                value: selectedResult,
                decoration: const InputDecoration(labelText: 'Shot Result'),
                items: ShotResult.values.map((result) => DropdownMenuItem(
                  value: result,
                  child: Text('${result.emoji} ${result.displayName}'),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedResult = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (clubController.text.trim().isNotEmpty) {
                  final distance = double.tryParse(distanceController.text);
                  
                  Navigator.pop(context);
                  
                  final success = await gameProvider.addManualShot(
                    clubId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                    clubName: clubController.text.trim(),
                    distance: distance,
                    result: selectedResult,
                  );
                  
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Manual shot added'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add Shot'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNFCTestDialog(GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test NFC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Simulate NFC tag reads:'),
            const SizedBox(height: 16),
            ...['driver_001', 'iron_7_001', 'wedge_pw_001', 'putter_001'].map(
              (tagId) => ListTile(
                title: Text(tagId),
                trailing: ElevatedButton(
                  onPressed: () {
                    gameProvider.simulateNfcTag(tagId);
                    Navigator.pop(context);
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shot Tracking Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to Track Shots:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Ensure GPS is enabled and ready'),
              Text('2. Tap your NFC-enabled club before each shot'),
              Text('3. The app will record your location and club used'),
              Text('4. Distance will be calculated automatically'),
              SizedBox(height: 16),
              Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Keep NFC tags close to your phone when tapping'),
              Text('• Make sure location permissions are enabled'),
              Text('• Use manual entry if NFC fails'),
              Text('• Complete the hole when finished'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}