import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:epansa_app/providers/alarm_provider.dart';
import 'package:epansa_app/data/models/alarm.dart';
import 'package:epansa_app/screens/alarm_edit_screen.dart';

/// Screen for managing user alarms
class AlarmManagementScreen extends StatefulWidget {
  const AlarmManagementScreen({super.key});

  @override
  State<AlarmManagementScreen> createState() => _AlarmManagementScreenState();
}

class _AlarmManagementScreenState extends State<AlarmManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Load alarms when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlarmProvider>().loadAlarms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarms'),
        elevation: 2,
      ),
      body: Consumer<AlarmProvider>(
        builder: (context, alarmProvider, child) {
          if (alarmProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (alarmProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    alarmProvider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => alarmProvider.loadAlarms(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final alarms = alarmProvider.alarms;

          if (alarms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.alarm,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No alarms yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to create one',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: alarms.length,
            itemBuilder: (context, index) {
              final alarm = alarms[index];
              return _AlarmCard(
                alarm: alarm,
                onToggle: () => alarmProvider.toggleAlarm(alarm.id),
                onEdit: () => _navigateToEdit(alarm),
                onDelete: () => _confirmDelete(alarm),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreate() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AlarmEditScreen(),
      ),
    );

    if (result == true && mounted) {
      // Reload alarms if one was created
      context.read<AlarmProvider>().loadAlarms();
    }
  }

  void _navigateToEdit(Alarm alarm) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlarmEditScreen(alarm: alarm),
      ),
    );

    if (result == true && mounted) {
      // Reload alarms if one was updated
      context.read<AlarmProvider>().loadAlarms();
    }
  }

  void _confirmDelete(Alarm alarm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alarm'),
        content: Text(
          'Are you sure you want to delete the alarm "${alarm.label}" at ${alarm.formattedTime}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AlarmProvider>().deleteAlarm(alarm.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Card widget for displaying an alarm
class _AlarmCard extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AlarmCard({
    required this.alarm,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Time display
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.formattedTime,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: alarm.enabled
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alarm.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: alarm.enabled ? null : Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alarm.repeatDaysString,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              
              // Delete button
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                tooltip: 'Delete',
              ),
              
              // Toggle switch
              Switch(
                value: alarm.enabled,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
