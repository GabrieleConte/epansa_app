import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:epansa_app/services/voice_input_service.dart';

/// Voice input bottom sheet dialog
class VoiceInputDialog extends StatefulWidget {
  final Function(String) onTextRecognized;

  const VoiceInputDialog({
    super.key,
    required this.onTextRecognized,
  });

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _initializeVoiceInput();
  }

  Future<void> _initializeVoiceInput() async {
    final voiceService = context.read<VoiceInputService>();
    
    try {
      final initialized = await voiceService.initialize();
      if (!initialized) {
        setState(() {
          _error = 'Voice input not available. Please check microphone permissions.';
        });
        return;
      }

      // Start listening
      await voiceService.startListening(
        onResult: (text) {
          if (text.isNotEmpty) {
            widget.onTextRecognized(text);
            Navigator.of(context).pop();
          }
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    final voiceService = context.read<VoiceInputService>();
    voiceService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          if (_error.isNotEmpty) ...[
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade700,
              ),
            ),
          ] else ...[
            // Animated microphone icon
            Consumer<VoiceInputService>(
              builder: (context, voiceService, child) {
                return AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: voiceService.isListening ? _scaleAnimation.value : 1.0,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF87CEEB).withValues(alpha: 0.2),
                          boxShadow: voiceService.isListening
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF87CEEB).withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          Icons.mic,
                          size: 48,
                          color: voiceService.isListening
                              ? const Color(0xFF4A90E2)
                              : Colors.grey.shade400,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Status text
            Consumer<VoiceInputService>(
              builder: (context, voiceService, child) {
                return Column(
                  children: [
                    Text(
                      voiceService.isListening
                          ? 'Listening...'
                          : 'Initializing...',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A90E2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (voiceService.lastWords.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F8FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          voiceService.lastWords,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      const Text(
                        'Speak now...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 24),

          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
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
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
