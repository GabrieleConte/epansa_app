import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:epansa_app/services/sync_service.dart';
import 'package:epansa_app/services/alarm_service.dart';
import 'package:epansa_app/presentation/screens/chat_screen.dart';

/// Sync setup screen - asks user to enable background sync
class SyncSetupScreen extends StatefulWidget {
  const SyncSetupScreen({super.key});

  @override
  State<SyncSetupScreen> createState() => _SyncSetupScreenState();
}

class _SyncSetupScreenState extends State<SyncSetupScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Request notification permissions when this screen loads
    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      final alarmService = context.read<AlarmService>();
      // This will trigger the iOS permission dialog if not already granted
      await alarmService.hasNotificationPermission();
      debugPrint('✅ Notification permissions checked on sync setup');
    } catch (e) {
      debugPrint('⚠️ Error checking notification permissions: $e');
    }
  }

  Future<void> _enableBackgroundSync() async {
    setState(() => _isLoading = true);

    final syncService = context.read<SyncService>();
    await syncService.enableBackgroundSync();

    if (!mounted) return;

    _navigateToChat();
  }

  void _skipBackgroundSync() {
    _navigateToChat();
  }

  void _navigateToChat() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const ChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF87CEEB),
              const Color(0xFF4A90E2),
              const Color(0xFF87CEEB).withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sync_rounded,
                    size: 50,
                    color: Color(0xFF4A90E2),
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                const Text(
                  'Enable Background Sync',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'EPANSA can automatically sync your data in the background to keep your assistant up-to-date.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // What gets synced
                _buildSyncItem(Icons.contacts_outlined, 'Contacts', 'Access contact information'),
                const SizedBox(height: 16),
                _buildSyncItem(Icons.calendar_today, 'Calendar', 'Manage your events'),
                const SizedBox(height: 16),
                _buildSyncItem(Icons.alarm, 'Alarms', 'Sync your device alarms'),
                const SizedBox(height: 16),
                _buildSyncItem(Icons.phone, 'Call History', 'Track phone call registry'),
                const SizedBox(height: 60),

                // Enable Button
                _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Column(
                        children: [
                          ElevatedButton(
                            onPressed: _enableBackgroundSync,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF4A90E2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                            ),
                            child: const Text(
                              'Enable Background Sync',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _skipBackgroundSync,
                            child: Text(
                              'Skip for now',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 24),

                // Info note
                Text(
                  'You can manually sync anytime using\nthe sync button in the chat screen',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSyncItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
