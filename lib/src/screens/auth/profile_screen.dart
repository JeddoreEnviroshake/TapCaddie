import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../config/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile', icon: Icon(Icons.person)),
            Tab(text: 'Clubs', icon: Icon(Icons.golf_course)),
            Tab(text: 'Stats', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.userModel;
          
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(user, authProvider),
              _buildClubsTab(user, authProvider),
              _buildStatsTab(user),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileTab(UserModel user, AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 60,
            backgroundImage: user.photoUrl != null 
                ? NetworkImage(user.photoUrl!) 
                : null,
            backgroundColor: AppTheme.primaryGreen,
            child: user.photoUrl == null 
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 36,
                      color: AppTheme.pureWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          
          const SizedBox(height: 16),
          
          // User Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Name'),
                    subtitle: Text(user.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditNameDialog(user, authProvider),
                    ),
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(user.email),
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Member Since'),
                    subtitle: Text(
                      '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick Stats Card
          Card(
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
                          'Clubs',
                          '${user.clubs.length}',
                          Icons.golf_course,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Distances',
                          '${user.clubDistances.length}',
                          Icons.straighten,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubsTab(UserModel user, AuthProvider authProvider) {
    return Column(
      children: [
        // Add Club Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddClubDialog(authProvider),
            icon: const Icon(Icons.add),
            label: const Text('Add Club'),
          ),
        ),
        
        // Clubs List
        Expanded(
          child: user.clubs.isEmpty
              ? const Center(
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
                        'No clubs added yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your clubs to start tracking shots',
                        style: TextStyle(color: AppTheme.mediumGray),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: user.clubs.length,
                  itemBuilder: (context, index) {
                    final club = user.clubs[index];
                    final distance = user.clubDistances[club.id];
                    
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryGreen,
                          child: Icon(
                            _getClubIcon(club.type),
                            color: AppTheme.pureWhite,
                          ),
                        ),
                        title: Text(club.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${club.type.displayName}'),
                            Text('NFC Tag: ${club.nfcTagId}'),
                            if (distance != null)
                              Text('Avg Distance: ${distance.round()} yds'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: AppTheme.errorRed),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditClubDialog(club, authProvider);
                            } else if (value == 'delete') {
                              _showDeleteClubDialog(club, authProvider);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatsTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Club Usage Stats
          if (user.clubs.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Club Distances',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ...user.clubs.map((club) {
                      final distance = user.clubDistances[club.id];
                      return ListTile(
                        leading: Icon(_getClubIcon(club.type)),
                        title: Text(club.name),
                        trailing: Text(
                          distance != null 
                              ? '${distance.round()} yds'
                              : 'No data',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
          
          // General Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Stats',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Total Clubs',
                          '${user.clubs.length}',
                          Icons.golf_course,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Club Types',
                          '${user.clubs.map((c) => c.type).toSet().length}',
                          Icons.category,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Days Active',
                          '${DateTime.now().difference(user.createdAt).inDays}',
                          Icons.calendar_today,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Profile Updates',
                          user.updatedAt != null ? '1+' : '0',
                          Icons.update,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.primaryGreen),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.mediumGray,
          ),
        ),
      ],
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

  void _showEditNameDialog(UserModel user, AuthProvider authProvider) {
    final controller = TextEditingController(text: user.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await authProvider.updateUserProfile(
                displayName: controller.text.trim(),
              );
              
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name updated successfully'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddClubDialog(AuthProvider authProvider) {
    final nameController = TextEditingController();
    final nfcTagController = TextEditingController();
    ClubType selectedType = ClubType.iron;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Club'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Club Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ClubType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Club Type'),
                items: ClubType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nfcTagController,
                decoration: const InputDecoration(labelText: 'NFC Tag ID'),
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
                if (nameController.text.trim().isNotEmpty &&
                    nfcTagController.text.trim().isNotEmpty) {
                  final club = Club(
                    id: const Uuid().v4(),
                    name: nameController.text.trim(),
                    type: selectedType,
                    nfcTagId: nfcTagController.text.trim(),
                  );
                  
                  final success = await authProvider.addOrUpdateClub(club);
                  
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Club added successfully'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditClubDialog(Club club, AuthProvider authProvider) {
    final nameController = TextEditingController(text: club.name);
    final nfcTagController = TextEditingController(text: club.nfcTagId);
    ClubType selectedType = club.type;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Club'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Club Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ClubType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Club Type'),
                items: ClubType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nfcTagController,
                decoration: const InputDecoration(labelText: 'NFC Tag ID'),
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
                if (nameController.text.trim().isNotEmpty &&
                    nfcTagController.text.trim().isNotEmpty) {
                  final updatedClub = club.copyWith(
                    name: nameController.text.trim(),
                    type: selectedType,
                    nfcTagId: nfcTagController.text.trim(),
                  );
                  
                  final success = await authProvider.addOrUpdateClub(updatedClub);
                  
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Club updated successfully'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteClubDialog(Club club, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Club'),
        content: Text('Are you sure you want to delete "${club.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            onPressed: () async {
              final success = await authProvider.removeClub(club.id);
              
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Club deleted successfully'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}