import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:epansa_app/providers/chat_provider.dart';
import 'package:epansa_app/services/auth_service.dart';
import 'package:epansa_app/services/sync_service.dart';
import 'package:epansa_app/presentation/widgets/message_bubble.dart';
import 'package:epansa_app/presentation/widgets/voice_input_dialog.dart';
import 'package:epansa_app/presentation/widgets/confirmation_dialog.dart';
import 'dart:math' as math;

/// Chat screen - main conversation interface
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EPANSA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Consumer<AuthService>(
              builder: (context, authService, child) {
                if (authService.isSignedIn) {
                  return Text(
                    authService.userName ?? 'Signed In',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          // User profile/settings
          Consumer<AuthService>(
            builder: (context, authService, child) {
              if (authService.isSignedIn) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    backgroundImage: authService.userPhotoUrl != null
                        ? NetworkImage(authService.userPhotoUrl!)
                        : null,
                    child: authService.userPhotoUrl == null
                        ? const Icon(Icons.person, color: Color(0xFF4A90E2))
                        : null,
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.login),
                onPressed: () async {
                  await authService.signIn();
                },
                tooltip: 'Sign In',
              );
            },
          ),
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'clear') {
                    context.read<ChatProvider>().clearMessages();
                  } else if (value == 'signout') {
                    context.read<AuthService>().signOut();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: Colors.black54),
                        SizedBox(width: 8),
                        Text('Clear Chat'),
                      ],
                    ),
                  ),
                  if (authService.isSignedIn)
                    const PopupMenuItem(
                      value: 'signout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.black54),
                          SizedBox(width: 8),
                          Text('Sign Out'),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                // Show confirmation dialog if there's a pending action
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (chatProvider.pendingAction != null) {
                    _showConfirmationDialog(chatProvider);
                  }
                });

                if (chatProvider.messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Start a conversation...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black38,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return MessageBubble(
                      message: message,
                      onConfirm: message.actionId != null
                          ? () {
                              chatProvider.confirmAction();
                              _scrollToBottom();
                            }
                          : null,
                      onDeny: message.actionId != null
                          ? () {
                              chatProvider.denyAction();
                              _scrollToBottom();
                            }
                          : null,
                    );
                  },
                );
              },
            ),
          ),

          // Loading indicator
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (!chatProvider.isLoading) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF4A90E2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'EPANSA is thinking...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              children: [
                // Voice input button
                IconButton(
                  onPressed: _showVoiceInput,
                  icon: const Icon(Icons.mic),
                  color: const Color(0xFF4A90E2),
                  tooltip: 'Voice Input',
                ),
                const SizedBox(width: 8),

                // Text input field
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF0F8FF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                CircleAvatar(
                  backgroundColor: const Color(0xFF4A90E2),
                  radius: 24,
                  child: IconButton(
                    onPressed: _handleSendMessage,
                    icon: const Icon(Icons.send),
                    color: Colors.white,
                    tooltip: 'Send',
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
