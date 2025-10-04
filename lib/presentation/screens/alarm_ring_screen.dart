import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';

/// Screen displayed when an alarm is ringing
/// Provides UI to stop or snooze the alarm
class AlarmRingScreen extends StatelessWidget {
  const AlarmRingScreen({
    super.key,
    required this.alarmSettings,
  });

  final AlarmSettings alarmSettings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Alarm icon
              const Icon(
                Icons.alarm,
                size: 120,
                color: Color(0xFF4A90E2),
              ),
              const SizedBox(height: 40),
              
              // Alarm title
              Text(
                alarmSettings.notificationSettings.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A90E2),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Alarm body
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  alarmSettings.notificationSettings.body,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 60),
              
              // Stop button
              ElevatedButton(
                onPressed: () async {
                  await Alarm.stop(alarmSettings.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stop, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Stop Alarm',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Snooze button
              OutlinedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final snoozeTime = now.add(const Duration(minutes: 5));
                  
                  // Set a new alarm for 5 minutes from now
                  await Alarm.set(
                    alarmSettings: alarmSettings.copyWith(
                      dateTime: snoozeTime,
                    ),
                  );
                  
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Alarm snoozed for 5 minutes'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4A90E2),
                  side: const BorderSide(
                    color: Color(0xFF4A90E2),
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.snooze, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Snooze (5 min)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
