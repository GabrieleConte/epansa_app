import 'package:flutter/material.dart';
import 'package:epansa_app/data/models/chat_message.dart';
import 'package:intl/intl.dart';

/// Message bubble widget for chat messages
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onConfirm;
  final VoidCallback? onDeny;

  const MessageBubble({
    super.key,
    required this.message,
    this.onConfirm,
    this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _buildAvatar(false),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _getBubbleColor(isUser, message.type),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: _getTextColor(isUser, message.type),
                          fontSize: 16,
                        ),
                      ),
                      if (message.type == MessageType.actionRequest) ...[
                        const SizedBox(height: 12),
                        _buildActionButtons(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    timeFormat.format(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor:
          isUser ? const Color(0xFF4A90E2) : const Color(0xFF87CEEB),
      child: Icon(
        isUser ? Icons.person : Icons.assistant,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: onConfirm,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Confirm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onDeny,
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Cancel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Color _getBubbleColor(bool isUser, MessageType type) {
    if (type == MessageType.error) {
      return Colors.red.shade50;
    }
    if (type == MessageType.actionConfirmed) {
      return Colors.green.shade50;
    }
    if (type == MessageType.actionDenied) {
      return Colors.orange.shade50;
    }
    return isUser
        ? const Color(0xFF4A90E2)
        : const Color(0xFFF0F8FF); // Alice blue
  }

  Color _getTextColor(bool isUser, MessageType type) {
    if (type == MessageType.error) {
      return Colors.red.shade900;
    }
    if (type == MessageType.actionConfirmed) {
      return Colors.green.shade900;
    }
    if (type == MessageType.actionDenied) {
      return Colors.orange.shade900;
    }
    return isUser ? Colors.white : Colors.black87;
  }
}
