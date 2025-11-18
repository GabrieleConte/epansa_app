import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:epansa_app/providers/chat_provider.dart';
import 'package:epansa_app/services/auth_service.dart';
import 'package:epansa_app/services/sync_service.dart';
import 'package:epansa_app/presentation/widgets/message_bubble.dart';
import 'package:epansa_app/presentation/widgets/voice_input_dialog.dart';
import 'package:epansa_app/presentation/widgets/confirmation_dialog.dart';
import 'package:epansa_app/presentation/screens/login_screen.dart';
import 'package:epansa_app/presentation/screens/notes_screen.dart';
import 'package:epansa_app/screens/alarm_management_screen.dart';
import 'dart:math' as math;

/// Enhanced chat screen with fancy UI similar to Apple Intelligence/Gemini
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _avatarAnimationController;
  late Animation<double> _avatarAnimation;

  @override
  void initState() {
    super.initState();
    
    // Avatar pulse animation
    _avatarAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _avatarAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _avatarAnimationController, curve: Curves.easeInOut),
    );

    // Add welcome message when chat starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().addWelcomeMessage();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _avatarAnimationController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _handleSendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    context.read<ChatProvider>().sendMessage(text);
    _scrollToBottom();
    _focusNode.unfocus();
  }

  void _showVoiceInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceInputDialog(
        onTextRecognized: (text) {
          context.read<ChatProvider>().sendMessage(text);
          _scrollToBottom();
        },
      ),
    );
  }

  void _showConfirmationDialog(chatProvider) {
    if (chatProvider.pendingAction == null) return;

    showDialog(
      context: context,
      builder: (context) => ActionConfirmationDialog(
        action: chatProvider.pendingAction!,
        onConfirm: () {
          chatProvider.confirmAction();
          _scrollToBottom();
        },
        onDeny: () {
          chatProvider.denyAction();
          _scrollToBottom();
        },
      ),
    );
  }

  Future<void> _handleSync() async {
    final syncService = context.read<SyncService>();
    final success = await syncService.performSync();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Sync completed' : 'Sync failed'),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Consumer<SyncService>(
              builder: (context, syncService, child) {
                return SwitchListTile(
                  title: const Text('Background Sync'),
                  subtitle: Text('Last sync: ${syncService.getSyncStatusMessage()}'),
                  value: syncService.isBackgroundSyncEnabled,
                  onChanged: (value) {
                    if (value) {
                      syncService.enableBackgroundSync();
                    } else {
                      syncService.disableBackgroundSync();
                    }
                  },
                  activeTrackColor: const Color(0xFF4A90E2),
                activeThumbColor: Colors.white,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Clear Chat History'),
              onTap: () async {
                Navigator.pop(context);
                await context.read<ChatProvider>().clearMessages();
                if (!context.mounted) return;
                context.read<ChatProvider>().addWelcomeMessage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out'),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthService>().signOut();
                // Force navigation to login screen
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF), // Very light blue background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF87CEEB),
                const Color(0xFF4A90E2),
              ],
            ),
          ),
        ),
        title: Row(
          children: [
            // Animated AI Avatar
            ScaleTransition(
              scale: _avatarAnimation,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFE3F2FD),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Color(0xFF4A90E2),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EPANSA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Notes button
          IconButton(
            icon: const Icon(Icons.note_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotesScreen(),
                ),
              );
            },
            tooltip: 'Notes',
          ),
          // Alarm Management button
          IconButton(
            icon: const Icon(Icons.alarm_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlarmManagementScreen(),
                ),
              );
            },
            tooltip: 'Manage alarms',
          ),
          // Sync button
          Consumer<SyncService>(
            builder: (context, syncService, child) {
              return IconButton(
                icon: syncService.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.sync_rounded),
                onPressed: syncService.isSyncing ? null : _handleSync,
                tooltip: 'Sync data',
              );
            },
          ),
          // Settings/Profile
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return IconButton(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  backgroundImage: authService.userPhotoUrl != null
                      ? NetworkImage(authService.userPhotoUrl!)
                      : null,
                  child: authService.userPhotoUrl == null
                      ? const Icon(
                          Icons.person,
                          color: Color(0xFF4A90E2),
                          size: 18,
                        )
                      : null,
                ),
                onPressed: _showSettingsMenu,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          // Show confirmation dialog if needed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (chatProvider.pendingAction != null) {
              _showConfirmationDialog(chatProvider);
            }
          });

          return Column(
            children: [
              // Messages list
              Expanded(
                child: chatProvider.messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: chatProvider.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatProvider.messages[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: MessageBubble(message: message),
                          );
                        },
                      ),
              ),

              // Loading indicator
              if (chatProvider.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTypingDot(0),
                      const SizedBox(width: 4),
                      _buildTypingDot(1),
                      const SizedBox(width: 4),
                      _buildTypingDot(2),
                    ],
                  ),
                ),

              // Input area
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Text input
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F8FF),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFB0E0E6),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    focusNode: _focusNode,
                                    decoration: const InputDecoration(
                                      hintText: 'Ask me anything...',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                    onSubmitted: (_) => _handleSendMessage(),
                                    textInputAction: TextInputAction.send,
                                  ),
                                ),
                                // Voice input button
                                IconButton(
                                  icon: const Icon(
                                    Icons.mic_rounded,
                                    color: Color(0xFF4A90E2),
                                  ),
                                  onPressed: _showVoiceInput,
                                  tooltip: 'Voice input',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Send button
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF87CEEB),
                                Color(0xFF4A90E2),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_upward_rounded),
                            color: Colors.white,
                            onPressed: _handleSendMessage,
                            tooltip: 'Send message',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF87CEEB),
                    Color(0xFF4A90E2),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hi! I\'m EPANSA',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your AI-powered personal assistant',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildSuggestionChip('What can you do?'),
            const SizedBox(height: 8),
            _buildSuggestionChip('Set an alarm for 7 AM'),
            const SizedBox(height: 8),
            _buildSuggestionChip('Show my recent calls'),
            const SizedBox(height: 8),
            _buildSuggestionChip('Create a meeting tomorrow'),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return InkWell(
      onTap: () {
        _textController.text = text;
        _handleSendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFB0E0E6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF4A90E2),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animValue = (value - delay).clamp(0.0, 1.0);
        final scale = math.sin(animValue * math.pi);
        
        return Transform.scale(
          scale: 0.5 + (scale * 0.5),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF4A90E2),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
