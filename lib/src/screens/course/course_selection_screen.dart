import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/course_model.dart';
import '../../config/app_theme.dart';

class CourseSelectionScreen extends StatefulWidget {
  const CourseSelectionScreen({super.key});

  @override
  State<CourseSelectionScreen> createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  int _selectedTabIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Course'),
        bottom: TabBar(
          onTap: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
          tabs: const [
            Tab(text: 'Templates', icon: Icon(Icons.golf_course)),
            Tab(text: 'Custom', icon: Icon(Icons.add_location)),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _buildTemplatesTab(),
          _buildCustomTab(),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    final templates = CourseTemplates.templates;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final course = templates[index];
        return _buildCourseCard(course);
      },
    );
  }

  Widget _buildCustomTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.construction,
                    size: 64,
                    color: AppTheme.mediumGray,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Custom Courses',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your own course layout or import from GPS data',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.mediumGray),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showCreateCourseDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Course'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _selectCourse(course),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.location,
                          style: const TextStyle(
                            color: AppTheme.mediumGray,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${course.holes.length} Holes',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Course Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildCourseStatItem(
                      'Par',
                      '${course.totalPar}',
                      Icons.flag,
                    ),
                  ),
                  Expanded(
                    child: _buildCourseStatItem(
                      'Distance',
                      '${course.totalDistance.round()} yds',
                      Icons.straighten,
                    ),
                  ),
                  Expanded(
                    child: _buildCourseStatItem(
                      'Rating',
                      course.rating?.toStringAsFixed(1) ?? 'N/A',
                      Icons.star,
                    ),
                  ),
                  Expanded(
                    child: _buildCourseStatItem(
                      'Slope',
                      '${course.slope}',
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Hole breakdown
              _buildHoleBreakdown(course),
              
              const SizedBox(height: 16),
              
              // Select button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _selectCourse(course),
                  child: const Text('Select Course'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.mediumGray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHoleBreakdown(CourseModel course) {
    final parCounts = <int, int>{};
    for (final hole in course.holes) {
      parCounts[hole.par] = (parCounts[hole.par] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hole Breakdown',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildParBreakdownItem('Par 3', parCounts[3] ?? 0),
              _buildParBreakdownItem('Par 4', parCounts[4] ?? 0),
              _buildParBreakdownItem('Par 5', parCounts[5] ?? 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParBreakdownItem(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
    );
  }

  void _selectCourse(CourseModel course) async {
    final gameProvider = context.read<GameProvider>();
    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to start a round'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final success = await gameProvider.selectCourse(course);
    
    if (success && mounted) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start New Round'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Course: ${course.name}'),
              Text('Holes: ${course.holes.length}'),
              Text('Par: ${course.totalPar}'),
              const SizedBox(height: 16),
              const Text('Ready to start your round?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                final startSuccess = await gameProvider.startNewRound(authProvider.userModel!.id);
                
                if (startSuccess && mounted) {
                  context.go('/scorecard?courseId=${course.id}');
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(gameProvider.errorMessage ?? 'Failed to start round'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              },
              child: const Text('Start Round'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gameProvider.errorMessage ?? 'Failed to select course'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _showCreateCourseDialog() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Custom Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Course Name',
                prefixIcon: Icon(Icons.golf_course),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Custom course creation is coming soon! For now, you can use the template courses.',
              style: TextStyle(
                color: AppTheme.mediumGray,
                fontSize: 14,
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Custom course creation coming soon!'),
                  backgroundColor: AppTheme.warningOrange,
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}