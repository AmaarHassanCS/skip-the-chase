import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message.dart';
import '../../models/match.dart';
import '../../models/user_profile.dart';
import '../../services/supabase_service.dart';
import '../../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  
  const ChatScreen({super.key, required this.matchId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  Match? _match;
  UserProfile? _otherUserProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatData();
  }

  Future<void> _loadChatData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      
      // Load match details
      final matches = await SupabaseService.getUserMatches(authProvider.user!.id);
      _match = matches.firstWhere((match) => match.id == widget.matchId);
      
      // Load other user's profile
      final otherUserId = _match!.getOtherUserId(authProvider.user!.id);
      _otherUserProfile = await SupabaseService.getUserProfile(otherUserId);
      
      // Load messages
      _messages = await SupabaseService.getMatchMessages(widget.matchId);
      
      setState(() => _isLoading = false);
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_match?.isExpired ?? true) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_otherUserProfile?.firstName ?? 'Chat'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'This match has expired',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Matches expire after 3 days of inactivity.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_otherUserProfile?.firstName ?? 'Chat'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Text('Block User'),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Text('Report User'),
              ),
            ],
            onSelected: _handleMenuAction,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final authProvider = context.read<AuthProvider>();
    final isMe = message.senderId == authProvider.user!.id;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.pink : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(message.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send, color: Colors.pink),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final authProvider = context.read<AuthProvider>();
    final content = _messageController.text.trim();
    _messageController.clear();
    
    try {
      final message = await SupabaseService.sendMessage(
        widget.matchId,
        authProvider.user!.id,
        content,
      );
      
      setState(() {
        _messages.add(message);
      });
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  void _handleMenuAction(String action) async {
    final authProvider = context.read<AuthProvider>();
    final otherUserId = _match!.getOtherUserId(authProvider.user!.id);
    
    switch (action) {
      case 'block':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Block User'),
            content: const Text('Are you sure you want to block this user?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Block'),
              ),
            ],
          ),
        );
        
        if (confirm == true) {
          await SupabaseService.blockUser(authProvider.user!.id, otherUserId);
          if (mounted) Navigator.pop(context);
        }
        break;
        
      case 'report':
        final reason = await showDialog<String>(
          context: context,
          builder: (context) {
            final controller = TextEditingController();
            return AlertDialog(
              title: const Text('Report User'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Reason for reporting...',
                ),
                maxLines: 3,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: const Text('Report'),
                ),
              ],
            );
          },
        );
        
        if (reason?.isNotEmpty == true) {
          await SupabaseService.reportUser(authProvider.user!.id, otherUserId, reason!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User reported')),
            );
          }
        }
        break;
    }
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}