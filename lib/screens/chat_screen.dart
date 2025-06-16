import 'package:flutter/material.dart';
import 'package:skip_the_chase/models/match.dart';
import 'package:skip_the_chase/models/message.dart';
import 'package:skip_the_chase/services/chat_service.dart';
import 'package:skip_the_chase/widgets/message_bubble.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatScreen extends StatefulWidget {
  final Match match;

  const ChatScreen({super.key, required this.match});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _chatService = ChatService();
  final _supabase = Supabase.instance.client;
  final List<Message> _messages = [];
  bool _isLoading = false;
  late final Stream<List<Message>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await _chatService.getMessages(widget.match.id);
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _subscribeToMessages() {
    final userId = _supabase.auth.currentUser!.id;

    _supabase
        .channel('public:messages:match_id=eq.${widget.match.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert, // Listen for INSERT events
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq, // Use enum instead of string 'eq'
            column: 'match_id',
            value: widget.match.id,
          ),
          callback: (payload) {
            final newMessage = Message.fromJson(payload.newRecord);
            setState(() {
              _messages.insert(0, newMessage);
            });
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      final userId = _supabase.auth.currentUser!.id;
      await _chatService.sendMessage(
        matchId: widget.match.id,
        senderId: userId,
        receiverId: widget.match.matchedUser.id,
        text: text,
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser!.id;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.match.matchedUser.avatarUrl != null
                  ? NetworkImage(widget.match.matchedUser.avatarUrl!)
                  : null,
              child: widget.match.matchedUser.avatarUrl == null
                  ? Text(widget.match.matchedUser.name[0])
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.match.matchedUser.name),
                Text(
                  'Matched ${timeago.format(widget.match.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // Video call functionality would go here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video calling coming soon!')),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'block') {
                // Block user functionality would go here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User blocked')),
                );
                Navigator.pop(context);
              } else if (value == 'report') {
                // Report user functionality would go here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User reported')),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'block',
                child: Text('Block User'),
              ),
              const PopupMenuItem<String>(
                value: 'report',
                child: Text('Report User'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Say hello to ${widget.match.matchedUser.name}!',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId == currentUserId;
                          return MessageBubble(
                            message: message,
                            isMe: isMe,
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}