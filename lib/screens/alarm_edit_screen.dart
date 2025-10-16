import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:epansa_app/providers/alarm_provider.dart';
import 'package:epansa_app/data/models/alarm.dart';

/// Screen for creating or editing an alarm
class AlarmEditScreen extends StatefulWidget {
  final Alarm? alarm; // null for creating new alarm

  const AlarmEditScreen({super.key, this.alarm});

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late TextEditingController _labelController;
  late TimeOfDay _selectedTime;
  late bool _enabled;
  late Set<int> _selectedDays;
  bool _isSaving = false;

  bool get isEditMode => widget.alarm != null;

  @override
  void initState() {
    super.initState();
    
    if (isEditMode) {
      // Editing existing alarm
      _labelController = TextEditingController(text: widget.alarm!.label);
      _selectedTime = TimeOfDay(
        hour: widget.alarm!.hour,
        minute: widget.alarm!.minute,
      );
      _enabled = widget.alarm!.enabled;
      _selectedDays = Set.from(widget.alarm!.repeatDays);
    } else {
      // Creating new alarm
      _labelController = TextEditingController();
      _selectedTime = TimeOfDay.now();
      _enabled = true;
      _selectedDays = {};
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Alarm' : 'New Alarm'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _saveAlarm,
              icon: const Icon(Icons.check),
              tooltip: 'Save alarm',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Picker
            _buildSection(
              title: 'Time',
              child: InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _formatTime(_selectedTime),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Label
            _buildSection(
              title: 'Label',
              child: TextField(
                controller: _labelController,
                decoration: InputDecoration(
                  hintText: 'Alarm name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            const SizedBox(height: 24),

            // Repeat Days
            _buildSection(
              title: 'Repeat',
              child: _buildDaySelector(),
            ),

            const SizedBox(height: 24),

            // Enabled Switch
            SwitchListTile(
              title: const Text('Enabled'),
              subtitle: const Text('Alarm will ring when enabled'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            const SizedBox(height: 32),

            // Delete button (only in edit mode)
            if (isEditMode)
              Center(
                child: OutlinedButton.icon(
                  onPressed: _deleteAlarm,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Alarm'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildDaySelector() {
    final days = [
      (1, 'Mon'),
      (2, 'Tue'),
      (3, 'Wed'),
      (4, 'Thu'),
      (5, 'Fri'),
      (6, 'Sat'),
      (7, 'Sun'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: days.map((day) {
        final dayNum = day.$1;
        final dayName = day.$2;
        final isSelected = _selectedDays.contains(dayNum);

        return FilterChip(
          label: Text(dayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(dayNum);
              } else {
                _selectedDays.remove(dayNum);
              }
            });
          },
          selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
          checkmarkColor: Theme.of(context).primaryColor,
        );
      }).toList(),
    );
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveAlarm() async {
    // Validate
    if (_labelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a label')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final alarmProvider = context.read<AlarmProvider>();
      bool success;

      if (isEditMode) {
        // Update existing alarm
        final updatedAlarm = widget.alarm!.copyWith(
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          label: _labelController.text.trim(),
          enabled: _enabled,
          repeatDays: _selectedDays.toList()..sort(),
          updatedAt: DateTime.now(),
        );
        success = await alarmProvider.updateAlarm(updatedAlarm);
      } else {
        // Create new alarm
        success = await alarmProvider.createAlarm(
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          label: _labelController.text.trim(),
          enabled: _enabled,
          repeatDays: _selectedDays.toList()..sort(),
        );
      }

      if (mounted) {
        setState(() => _isSaving = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditMode ? 'Alarm updated!' : 'Alarm created!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                alarmProvider.error ?? 'Failed to save alarm',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAlarm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alarm'),
        content: const Text('Are you sure you want to delete this alarm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<AlarmProvider>().deleteAlarm(widget.alarm!.id);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alarm deleted'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete alarm'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
