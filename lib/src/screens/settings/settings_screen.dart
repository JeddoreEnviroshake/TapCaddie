import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.userModel;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Edit Profile'),
                        subtitle: const Text('Update your personal information'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/profile'),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // App Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Settings',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notifications'),
                        subtitle: const Text('Manage notification preferences'),
                        trailing: Switch(
                          value: true, // TODO: Implement actual setting
                          onChanged: (value) {
                            // TODO: Implement notification toggle
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: const Text('Location Services'),
                        subtitle: const Text('Allow GPS tracking for shots'),
                        trailing: Switch(
                          value: true, // TODO: Implement actual setting
                          onChanged: (value) {
                            // TODO: Implement location toggle
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.nfc),
                        title: const Text('NFC Settings'),
                        subtitle: const Text('Configure NFC tag detection'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showNFCSettings(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Data & Privacy
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data & Privacy',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.download),
                        title: const Text('Export Data'),
                        subtitle: const Text('Download your golf data'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showExportDataDialog(),
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_sweep),
                        title: const Text('Clear Data'),
                        subtitle: const Text('Remove all local data'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showClearDataDialog(),
                      ),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip),
                        title: const Text('Privacy Policy'),
                        subtitle: const Text('View our privacy policy'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showPrivacyPolicy(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // About
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('App Version'),
                        subtitle: const Text('1.0.0'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.help),
                        title: const Text('Help & Support'),
                        subtitle: const Text('Get help with TapCaddie'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showHelpDialog(),
                      ),
                      ListTile(
                        leading: const Icon(Icons.rate_review),
                        title: const Text('Rate App'),
                        subtitle: const Text('Rate TapCaddie on the App Store'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showRateAppDialog(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Account Actions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.logout, color: AppTheme.errorRed),
                        title: const Text('Sign Out', style: TextStyle(color: AppTheme.errorRed)),
                        onTap: () => _showSignOutDialog(authProvider),
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: AppTheme.errorRed),
                        title: const Text('Delete Account', style: TextStyle(color: AppTheme.errorRed)),
                        onTap: () => _showDeleteAccountDialog(authProvider),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showNFCSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('NFC Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NFC Configuration'),
            SizedBox(height: 16),
            Text('• Ensure NFC is enabled on your device'),
            Text('• Keep NFC tags close to the device when tapping'),
            Text('• Use the NFC test feature to verify functionality'),
            SizedBox(height: 16),
            Text('Current Status: Simulation Mode'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExportDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'Export your golf data including rounds, shots, and analytics. '
          'This feature will be available in a future update.',
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
                  content: Text('Data export coming soon!'),
                  backgroundColor: AppTheme.warningOrange,
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Data'),
        content: const Text(
          'This will remove all locally cached data. Your cloud data will remain safe. '
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Local data cleared'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'TapCaddie Privacy Policy\n\n'
            '1. Data Collection\n'
            'We collect golf performance data, location data for shot tracking, and user profile information.\n\n'
            '2. Data Usage\n'
            'Your data is used to provide golf analytics and improve your game experience.\n\n'
            '3. Data Sharing\n'
            'We do not share your personal data with third parties without your consent.\n\n'
            '4. Data Security\n'
            'Your data is stored securely using Firebase security protocols.\n\n'
            'For the full privacy policy, visit our website.',
          ),
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
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Getting Started:'),
            Text('1. Add your clubs in the Profile section'),
            Text('2. Select a course and start a round'),
            Text('3. Tap NFC tags on your clubs during shots'),
            Text('4. View your analytics after the round'),
            SizedBox(height: 16),
            Text('Need more help?'),
            Text('Email: support@tapcaddie.com'),
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

  void _showRateAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate TapCaddie'),
        content: const Text(
          'Enjoying TapCaddie? Please rate us on the App Store to help other golfers discover our app!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your support!'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(context);
              final success = await authProvider.signOut();
              if (success && mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(AuthProvider authProvider) {
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action cannot be undone. All your data will be permanently deleted.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter your password to confirm',
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              if (passwordController.text.isNotEmpty) {
                Navigator.pop(context);
                final success = await authProvider.deleteAccount(passwordController.text);
                if (success && mounted) {
                  context.go('/login');
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authProvider.errorMessage ?? 'Failed to delete account'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}