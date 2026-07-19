import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/data/loverage_repository.dart';
import '../../authentication/domain/account_status.dart';
import '../../verification/presentation/verification_pending_banner.dart';
import '../../../app/router/app_router.dart';

class ChatsTab extends ConsumerStatefulWidget {
  final int initialTabIndex;
  final int initialRequestTabIndex;
  const ChatsTab({
    super.key,
    this.initialTabIndex = 0,
    this.initialRequestTabIndex = 1,
  });

  @override
  ConsumerState<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends ConsumerState<ChatsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _isLoading = false;
  List<_Chat> _chats = [];
  List<_Request> _receivedRequests = [];
  List<_Request> _sentRequests = [];
  late int _requestTabIndex;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _requestTabIndex = widget.initialRequestTabIndex.clamp(0, 1);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData();
  }

  @override
  void didUpdateWidget(covariant ChatsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextTab = widget.initialTabIndex.clamp(0, 1);
    if (oldWidget.initialTabIndex != widget.initialTabIndex &&
        _tabCtrl.index != nextTab) {
      _tabCtrl.animateTo(nextTab);
    }
    if (oldWidget.initialRequestTabIndex != widget.initialRequestTabIndex) {
      _requestTabIndex = widget.initialRequestTabIndex.clamp(0, 1);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  LoverageRepository get _repository =>
      LoverageRepository(Supabase.instance.client);

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await _repository.conversations();
      final receivedRequests = await _repository.incomingChatRequests();
      final sentRequests = await _repository.sentChatRequests();
      if (!mounted) return;
      setState(() {
        _chats = conversations.map(_chatFromRow).toList();
        _receivedRequests = receivedRequests
            .map((row) => _requestFromRow(row, profileKey: 'sender'))
            .toList();
        _sentRequests = sentRequests
            .map((row) => _requestFromRow(row, profileKey: 'receiver'))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load messages: $e')));
    }
  }

  Future<void> _acceptRequest(_Request r) async {
    try {
      final conversationId = await _repository.acceptChatRequest(r.id);
      if (!mounted) return;
      setState(() => _receivedRequests.removeWhere((x) => x.id == r.id));
      context.push('/chat/$conversationId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not accept request: $e')));
      }
    }
  }

  Future<void> _declineRequest(_Request r) async {
    try {
      await _repository.declineChatRequest(r.id);
      if (mounted) {
        setState(() => _receivedRequests.removeWhere((x) => x.id == r.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not decline request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authStatusProvider).valueOrNull;
    final isPendingReview = authStatus == AccountStatus.verificationPending;

    if (isPendingReview) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          title: Text(
            'Messages',
            style: AppTheme.sansText(
              fontSize: 16.0,
              weight: FontWeight.w300,
              color: Colors.white.withOpacity(0.9),
            ).copyWith(letterSpacing: 0.5),
          ),
          centerTitle: false,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('Assets/home background .png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              const VerificationPendingBanner(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.07),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hourglass_empty_rounded,
                          size: 40,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Review in progress',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          'Your Account is under review will be active soon.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        title: Text(
          'Messages',
          style: AppTheme.sansText(
            fontSize: 16.0,
            weight: FontWeight.w300,
            color: Colors.white.withOpacity(0.9),
          ).copyWith(letterSpacing: 0.5),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('Assets/home background .png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryBurgundy,
                ),
              )
            : Column(
                children: [
                  // Modern Pill Selector
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 6,
                    ), // Sleeker width and margin
                    padding: const EdgeInsets.all(3), // More compact padding
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EAE6), // soft warm cream-grey
                      borderRadius: BorderRadius.circular(AppRadius.circular),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _tabCtrl.animateTo(0),
                            child: Container(
                              height: 30, // Smaller compact height
                              decoration: BoxDecoration(
                                gradient: _tabCtrl.index == 0
                                    ? AppColors.roseGoldGradient
                                    : null,
                                color: _tabCtrl.index == 0
                                    ? null
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.circular,
                                ),
                                boxShadow: _tabCtrl.index == 0
                                    ? [
                                        BoxShadow(
                                          color: AppColors.accentRoseGold
                                              .withOpacity(0.20),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Chats',
                                    style: TextStyle(
                                      color: _tabCtrl.index == 0
                                          ? AppColors.primaryDarkBurgundy
                                          : AppColors.textSecondary,
                                      fontWeight: _tabCtrl.index == 0
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      fontSize: 12.5, // Sleeker font size
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _tabCtrl.index == 0
                                          ? AppColors.primaryBurgundy
                                          : const Color(
                                              0xFFD4C8C2,
                                            ), // Distinct active/inactive badge colors
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _chats.length.toString(),
                                      style: TextStyle(
                                        color: _tabCtrl.index == 0
                                            ? Colors.white
                                            : const Color(0xFF7E726C),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _tabCtrl.animateTo(1),
                            child: Container(
                              height: 30, // Smaller compact height
                              decoration: BoxDecoration(
                                gradient: _tabCtrl.index == 1
                                    ? AppColors.roseGoldGradient
                                    : null,
                                color: _tabCtrl.index == 1
                                    ? null
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.circular,
                                ),
                                boxShadow: _tabCtrl.index == 1
                                    ? [
                                        BoxShadow(
                                          color: AppColors.accentRoseGold
                                              .withOpacity(0.20),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Requests',
                                    style: TextStyle(
                                      color: _tabCtrl.index == 1
                                          ? AppColors.primaryDarkBurgundy
                                          : AppColors.textSecondary,
                                      fontWeight: _tabCtrl.index == 1
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      fontSize: 12.5, // Sleeker font size
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _tabCtrl.index == 1
                                          ? AppColors.primaryBurgundy
                                          : const Color(
                                              0xFFD4C8C2,
                                            ), // Distinct active/inactive badge colors
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      (_receivedRequests.length +
                                              _sentRequests.length)
                                          .toString(),
                                      style: TextStyle(
                                        color: _tabCtrl.index == 1
                                            ? Colors.white
                                            : const Color(0xFF7E726C),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _ChatList(chats: _chats),
                        _RequestsTab(
                          sentRequests: _sentRequests,
                          receivedRequests: _receivedRequests,
                          selectedIndex: _requestTabIndex,
                          onTabChanged: (index) =>
                              setState(() => _requestTabIndex = index),
                          onAccept: _acceptRequest,
                          onDecline: _declineRequest,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

_Chat _chatFromRow(Map<String, dynamic> row) {
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  final partner = row['participant_a'] == currentUserId
      ? row['b'] as Map<String, dynamic>?
      : row['a'] as Map<String, dynamic>?;
  final repo = LoverageRepository(Supabase.instance.client);
  final messages = row['messages'] is List
      ? List<Map<String, dynamic>>.from(row['messages'] as List)
      : <Map<String, dynamic>>[];
  messages.sort(
    (a, b) => (b['created_at'] ?? '').toString().compareTo(
      (a['created_at'] ?? '').toString(),
    ),
  );
  final last = messages.isNotEmpty ? messages.first : null;
  final seen = DateTime.tryParse((partner?['last_seen_at'] ?? '').toString());
  final isOnline =
      seen != null && DateTime.now().difference(seen).inMinutes < 15;
  return _Chat(
    id: row['id'].toString(),
    name: (partner?['public_name'] as String?) ?? 'Loverage member',
    imageUrl: repo.photoUrl(partner),
    lastMsg: (last?['body'] as String?) ?? 'Start the conversation',
    time: _timeAgo(
      DateTime.tryParse(
        (last?['created_at'] ?? row['updated_at'] ?? '').toString(),
      ),
    ),
    unread: messages
        .where((m) => m['sender_id'] != currentUserId && m['read_at'] == null)
        .length,
    isOnline: isOnline,
    age: (partner?['age'] as num?)?.toInt() ?? 0,
    country: (partner?['public_country_code'] as String?) ?? '',
    lastActive: isOnline ? 'Online' : _timeAgo(seen),
    isVerified: partner?['verification_status'] == 'approved',
  );
}

_Request _requestFromRow(
  Map<String, dynamic> row, {
  required String profileKey,
}) {
  final sender = row[profileKey] as Map<String, dynamic>? ?? const {};
  final repo = LoverageRepository(Supabase.instance.client);
  return _Request(
    id: row['id'].toString(),
    name: (sender['public_name'] as String?) ?? 'Loverage member',
    age: (sender['age'] as num?)?.toInt() ?? 0,
    city:
        (sender['public_city'] as String?) ??
        (sender['public_country_code'] as String?) ??
        'Nearby',
    imageUrl: repo.photoUrl(sender),
    intro: (row['introduction'] as String?) ?? 'Sent you a message request.',
  );
}

String _timeAgo(DateTime? value) {
  if (value == null) return 'Recently';
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'Now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat List
// ─────────────────────────────────────────────────────────────────────────────
class _ChatList extends StatelessWidget {
  final List<_Chat> chats;
  const _ChatList({required this.chats});

  @override
  Widget build(BuildContext context) {
    if (chats.isEmpty) {
      return const _EmptyState(
        message:
            'No active conversations yet.\nAccept a request to start chatting.',
        assetPath: 'Assets/empty MESSAGES 2 (1).png',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        100,
      ), // Padded list for cards layout
      itemCount: chats.length,
      itemBuilder: (_, i) => _ChatTile(chat: chats[i]),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final _Chat chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unread > 0;
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 7,
        horizontal: 4,
      ), // Spacing between chat cards
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF7D070), // bright gold
            Color(0xFFC59F4E), // rich deep gold
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ), // Premium iPhone rounded squircle radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(
        1.2,
      ), // Thickness of the gradient border stroke
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Solid white card body
          borderRadius: BorderRadius.circular(19), // Nested corner radius
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/chat/${chat.id}'),
            borderRadius: BorderRadius.circular(19),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar with online dot
                  Stack(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFFE8B86D),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(2.5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network(
                            chat.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: chat.isOnline
                                ? const Color(0xFF22C55E)
                                : const Color(
                                    0xFF94A3B8,
                                  ), // green online, grey offline
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceWhite,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Message Info (Name & Last Message)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${chat.name}, ${chat.age}',
                              style: TextStyle(
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (chat.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF60A5FA),
                                size: 13,
                              ),
                            ],
                            const SizedBox(width: 4),
                            Text(
                              _getCountryFlag(chat.country),
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (chat.isNew) ...[
                              const SizedBox(width: 6),
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
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: chat.isOnline
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              chat.isOnline
                                  ? 'Online'
                                  : 'Active ${chat.lastActive}',
                              style: TextStyle(
                                color: chat.isOnline
                                    ? const Color(0xFF22C55E)
                                    : AppColors.textMuted,
                                fontSize: 10.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chat.lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasUnread
                                ? AppColors.textPrimary.withOpacity(0.9)
                                : AppColors.textSecondary,
                            fontSize: 12.0, // smaller and more elegant
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Trailing time & unread badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        chat.time,
                        style: TextStyle(
                          fontSize: 10.5, // smaller and more elegant
                          color: hasUnread
                              ? AppColors.primaryBurgundy
                              : AppColors.textMuted,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBurgundy,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            chat.unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Requests List
// ─────────────────────────────────────────────────────────────────────────────
class _RequestsTab extends StatelessWidget {
  final List<_Request> sentRequests;
  final List<_Request> receivedRequests;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final void Function(_Request) onAccept;
  final void Function(_Request) onDecline;

  const _RequestsTab({
    required this.sentRequests,
    required this.receivedRequests,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final showingSent = selectedIndex == 0;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(24, 10, 24, 4),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1EAE6),
            borderRadius: BorderRadius.circular(AppRadius.circular),
          ),
          child: Row(
            children: [
              _RequestSegmentButton(
                label: 'Sent Requests',
                count: sentRequests.length,
                selected: showingSent,
                onTap: () => onTabChanged(0),
              ),
              _RequestSegmentButton(
                label: 'Received Requests',
                count: receivedRequests.length,
                selected: !showingSent,
                onTap: () => onTabChanged(1),
              ),
            ],
          ),
        ),
        Expanded(
          child: _RequestList(
            requests: showingSent ? sentRequests : receivedRequests,
            mode: showingSent
                ? _RequestListMode.sent
                : _RequestListMode.received,
            onAccept: onAccept,
            onDecline: onDecline,
          ),
        ),
      ],
    );
  }
}

class _RequestSegmentButton extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _RequestSegmentButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 30,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.roseGoldGradient : null,
            borderRadius: BorderRadius.circular(AppRadius.circular),
          ),
          alignment: Alignment.center,
          child: Text(
            '$label  $count',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected
                  ? AppColors.primaryDarkBurgundy
                  : AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

enum _RequestListMode { sent, received }

class _RequestList extends StatelessWidget {
  final List<_Request> requests;
  final _RequestListMode mode;
  final void Function(_Request) onAccept;
  final void Function(_Request) onDecline;
  const _RequestList({
    required this.requests,
    required this.mode,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const _EmptyState(
        message: 'No pending requests.\nMessage requests will appear here.',
        assetPath: 'Assets/empty MESSAGES 2 (1).png',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (_, i) => _RequestCard(
        r: requests[i],
        mode: mode,
        onAccept: onAccept,
        onDecline: onDecline,
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final _Request r;
  final _RequestListMode mode;
  final void Function(_Request) onAccept;
  final void Function(_Request) onDecline;
  const _RequestCard({
    required this.r,
    required this.mode,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Match iPhone card radius
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE8B86D),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(2.5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(r.imageUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r.name}, ${r.age}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.city,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppRadius.s),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              r.intro,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (mode == _RequestListMode.received)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onDecline(r),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      side: const BorderSide(color: AppColors.borderMedium),
                      foregroundColor: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onAccept(r),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.premiumBurgundyGradient,
                        borderRadius: BorderRadius.circular(AppRadius.circular),
                        border: Border.all(
                          color: const Color(0xFFD4956A),
                          width: 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'Assets/accept.png',
                            width: 14,
                            height: 14,
                            color: const Color(0xFFF7D5C4),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Accept',
                            style: TextStyle(
                              color: Color(0xFFF7D5C4),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            const Text(
              'Pending response',
              style: TextStyle(
                color: AppColors.primaryBurgundy,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String assetPath;
  const _EmptyState({required this.message, required this.assetPath});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(assetPath, width: 150, height: 150, fit: BoxFit.contain),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14.5,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}

// ─── Models ──────────────────────────────────────────────────────────────────
class _Chat {
  final String id, name, imageUrl, lastMsg, time, country, lastActive;
  final int unread, age;
  final bool isOnline, isVerified, isNew;
  const _Chat({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.lastMsg,
    required this.time,
    required this.unread,
    required this.isOnline,
    required this.age,
    required this.country,
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

class _Request {
  final String id, name, city, imageUrl, intro;
  final int age;
  const _Request({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    required this.imageUrl,
    required this.intro,
  });
}
