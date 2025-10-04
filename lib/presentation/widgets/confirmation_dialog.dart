import 'package:flutter/material.dart';
import 'package:epansa_app/data/models/chat_message.dart';

/// Confirmation dialog for sensitive actions
class ActionConfirmationDialog extends StatelessWidget {
  final PendingAction action;
  final VoidCallback onConfirm;
  final VoidCallback onDeny;

  const ActionConfirmationDialog({
    super.key,
    required this.action,
    required this.onConfirm,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF87CEEB).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getActionIcon(),
                size: 32,
                color: const Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Confirm Action',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A90E2),
                  ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              action.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Action type
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getActionTypeText(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A90E2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Warning message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, 
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getWarningMessage(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDeny();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon() {
    switch (action.type) {
      case ActionType.sendSms:
        return Icons.message;
      case ActionType.makeCall:
        return Icons.phone;
      case ActionType.setAlarm:
        return Icons.alarm;
      case ActionType.createEvent:
        return Icons.event;
      case ActionType.sendEmail:
        return Icons.email;
      default:
        return Icons.touch_app;
    }
  }

  String _getActionTypeText() {
    switch (action.type) {
      case ActionType.sendSms:
        return 'SEND SMS';
      case ActionType.makeCall:
        return 'MAKE CALL';
      case ActionType.setAlarm:
        return 'SET ALARM';
      case ActionType.createEvent:
        return 'CREATE EVENT';
      case ActionType.sendEmail:
        return 'SEND EMAIL';
      default:
        return 'ACTION';
    }
  }

  String _getWarningMessage() {
    switch (action.type) {
      case ActionType.sendSms:
        return 'This will send an SMS from your device. Message charges may apply.';
      case ActionType.makeCall:
        return 'This will initiate a phone call from your device.';
      case ActionType.setAlarm:
        return 'This will create an alarm on your device.';
      case ActionType.createEvent:
        return 'This will add an event to your calendar.';
      case ActionType.sendEmail:
        return 'This will send an email from your account.';
      default:
        return 'Please confirm you want to proceed with this action.';
    }
  }
}
