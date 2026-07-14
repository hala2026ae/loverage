import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/data/loverage_repository.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  const ChatDetailScreen({super.key, required this.conversationId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  _ChatPartner? _partner;
  bool _isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isPartnerTyping = false;
  List<ChatMessage> _messages = [];

  LoverageRepository get _repository =>
      LoverageRepository(Supabase.instance.client);

  _ChatPartner _getPartner() {
    return _partner ??
        const _ChatPartner(
          name: 'Loverage member',
          age: 0,
          country: '',
          imageUrl:
              'https://ui-avatars.com/api/?background=5E0B24&color=fff&name=Loverage',
          isOnline: false,
          lastActive: 'Recently',
          isVerified: false,
        );
  }

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    try {
      final partner = await _repository.conversationPartner(
        widget.conversationId,
      );
      final rows = await _repository.messages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _partner = _partnerFromRow(partner);
        _messages = rows.map(_messageFromRow).toList();
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load conversation: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (text.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message exceeds 2,000 characters limit.'),
        ),
      );
      return;
    }

    final optimistic = ChatMessage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      senderId: Supabase.instance.client.auth.currentUser?.id ?? 'me',
      content: text,
      timestamp: 'Just now',
    );

    setState(() => _messages.add(optimistic));
    _messageController.clear();
    _scrollToBottom();

    try {
      await _repository.sendMessage(widget.conversationId, text);
      await _loadConversation();
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.removeWhere((m) => m.id == optimistic.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send message: $e')));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPartner = _getPartner();
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryBurgundy,
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8B86D), width: 1.2),
              ),
              padding: const EdgeInsets.all(2.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.network(
                  currentPartner.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '${currentPartner.name}, ${currentPartner.age}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (currentPartner.isVerified) ...[
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF60A5FA),
                          size: 12,
                        ),
                      ],
                      const SizedBox(width: 3),
                      Text(
                        _getCountryFlag(currentPartner.country),
                        style: const TextStyle(fontSize: 11),
                      ),
                      if (currentPartner.isNew) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: currentPartner.isOnline
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentPartner.isOnline
                            ? 'Online'
                            : 'Active ${currentPartner.lastActive}',
                        style: TextStyle(
                          fontSize: 10.0,
                          color: currentPartner.isOnline
                              ? const Color(0xFF22C55E)
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.primaryBurgundy,
            ),
            onSelected: (value) {
              if (value == 'block') {
                _showBlockDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Text(
                  'Block and Archive',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('Assets/new chats.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryBurgundy,
                ),
              )
            : SafeArea(
                child: Column(
                  children: [
                    // Messages Stream
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.m),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe =
                              msg.senderId ==
                              Supabase.instance.client.auth.currentUser?.id;
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
                    ),

                    // Typing Indicator
                    if (_isPartnerTyping)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.s,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              height: 12.0,
                              width: 12.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              '${currentPartner.name} is typing...',
                              style: const TextStyle(
                                fontSize: 12.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Message Input bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.s,
                      ),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              maxLength: 2000,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                counterText: '', // Hide counter
                                filled: true,
                                fillColor: AppColors.backgroundLight,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          GestureDetector(
                            onTap: _sendMessage,
                            child: const CircleAvatar(
                              radius: 24.0,
                              backgroundColor: AppColors.primaryBurgundy,
                              child: Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20.0,
                              ),
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

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.roseGoldGradient : null,
          color: isMe ? null : const Color(0xFFF1EAE6), // soft warm cream-grey
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20.0),
            topRight: const Radius.circular(20.0),
            bottomLeft: Radius.circular(isMe ? 20.0 : 4.0),
            bottomRight: Radius.circular(isMe ? 4.0 : 20.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: TextStyle(
                color: isMe
                    ? AppColors.primaryDarkBurgundy
                    : AppColors.textPrimary,
                fontSize: 14.5,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 5.0),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                msg.timestamp,
                style: TextStyle(
                  color: isMe
                      ? AppColors.primaryDarkBurgundy.withOpacity(0.6)
                      : AppColors.textMuted,
                  fontSize: 10.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundLight,
          title: const Text('Block and Archive'),
          content: const Text(
            'Are you sure you want to block Victoria? The conversation will be hidden, and you will no longer receive messages.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop(); // Go back to chats list
              },
              child: const Text(
                'Block',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final String timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
  });
}

_ChatPartner _partnerFromRow(Map<String, dynamic>? row) {
  final repo = LoverageRepository(Supabase.instance.client);
  final seen = DateTime.tryParse((row?['last_seen_at'] ?? '').toString());
  final isOnline =
      seen != null && DateTime.now().difference(seen).inMinutes < 15;
  return _ChatPartner(
    name: (row?['public_name'] as String?) ?? 'Loverage member',
    age: (row?['age'] as num?)?.toInt() ?? 0,
    country: (row?['public_country_code'] as String?) ?? '',
    imageUrl: repo.photoUrl(row),
    isOnline: isOnline,
    lastActive: isOnline ? 'Online' : _timeAgo(seen),
    isVerified: row?['verification_status'] == 'approved',
  );
}

ChatMessage _messageFromRow(Map<String, dynamic> row) {
  return ChatMessage(
    id: row['id'].toString(),
    senderId: row['sender_id'].toString(),
    content: (row['body'] as String?) ?? '',
    timestamp: _timeAgo(
      DateTime.tryParse((row['created_at'] ?? '').toString()),
    ),
  );
}

String _timeAgo(DateTime? value) {
  if (value == null) return 'Recently';
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class _ChatPartner {
  final String name, country, imageUrl, lastActive;
  final int age;
  final bool isVerified, isOnline, isNew;
  const _ChatPartner({
    required this.name,
    required this.age,
    required this.country,
    required this.imageUrl,
    required this.isOnline,
    required this.lastActive,
    required this.isVerified,
    this.isNew = false,
  });
}

String _getCountryFlag(String country) {
  switch (country.toUpperCase()) {
    case 'UK':
      return '🇬🇧';
    case 'USA':
      return '🇺🇸';
    case 'CANADA':
      return '🇨🇦';
    case 'FRANCE':
      return '🇫🇷';
    case 'UAE':
      return '🇦🇪';
    case 'EGYPT':
      return '🇪🇬';
    case 'AUSTRALIA':
      return '🇦🇺';
    case 'SINGAPORE':
      return '🇸🇬';
    default:
      return '🏳️';
  }
}
