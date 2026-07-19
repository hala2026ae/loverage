import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyActionLimitException implements Exception {
  final String action;
  final int limit;
  final int sent;

  const DailyActionLimitException({
    required this.action,
    required this.limit,
    required this.sent,
  });

  int get remaining => (limit - sent).clamp(0, limit);

  @override
  String toString() => 'Daily $action limit reached';
}

enum DailyUsageAction { knock, chatRequest }

class DailyUsageChange {
  final DailyUsageAction action;
  final int used;
  final int remaining;
  final int limit;

  const DailyUsageChange({
    required this.action,
    required this.used,
    required this.remaining,
    required this.limit,
  });
}

class LoverageRepository {
  LoverageRepository(this._supabase);
  final SupabaseClient _supabase;

  static final dailyUsageChanged = ValueNotifier<DailyUsageChange?>(null);
  static Future<void> _usageQueue = Future<void>.value();
  static final Map<String, Map<String, dynamic>> _profileCache = {};
  static final Map<String, String?> _viewerGenderCache = {};

  static const _knockLimit = 20;
  static const _chatLimit = 5;

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw Exception('You must be signed in.');
    return id;
  }

  Future<List<Map<String, dynamic>>> feedProfiles({
    String filter = 'All',
    int page = 0,
    int pageSize = 12,
  }) async {
    String? viewerGender = _viewerGenderCache[_userId];
    if (!_viewerGenderCache.containsKey(_userId)) {
      final viewer = await _supabase
          .from('profiles')
          .select('gender')
          .eq('id', _userId)
          .maybeSingle();
      viewerGender = viewer?['gender'] as String?;
      _viewerGenderCache[_userId] = viewerGender;
    }

    var query = _supabase
        .from('profiles')
        .select(
          'id, public_name, age, public_city, public_country_code, profession, bio, traits, verification_status, is_premium, last_seen_at, created_at, profile_photos(id, public_url, is_primary, sort_order)',
        )
        .eq('profile_status', 'active')
        .eq('verification_status', 'approved')
        .eq('is_hidden', false)
        .neq('id', _userId);

    if (viewerGender != null && viewerGender.isNotEmpty) {
      query = query.neq('gender', viewerGender);
    }

    if (filter == 'New') {
      query = query.gte(
        'created_at',
        DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
      );
    }
    if (filter == 'Online') {
      query = query.gte(
        'last_seen_at',
        DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      );
    }

    final from = page * pageSize;
    final rows = await query
        .order('last_seen_at', ascending: false)
        .range(from, from + pageSize - 1);
    final profiles = List<Map<String, dynamic>>.from(rows as List);
    for (final profile in profiles) {
      final id = profile['id']?.toString();
      if (id != null) {
        _profileCache[id] = {...?_profileCache[id], ...profile};
      }
    }
    return profiles;
  }

  Map<String, dynamic>? cachedProfile(String id) {
    final cached = _profileCache[id];
    return cached == null ? null : Map<String, dynamic>.from(cached);
  }

  Future<Map<String, dynamic>?> profile(String id) async {
    final row = await _supabase
        .from('profiles')
        .select(
          'id, public_name, age, public_city, public_country_code, profession, education, languages, religion, bio, traits, verification_status, is_premium, last_seen_at, created_at, profile_photos(id, public_url, is_primary, sort_order)',
        )
        .eq('id', id)
        .maybeSingle();
    if (row == null) return cachedProfile(id);
    final merged = {...?_profileCache[id], ...row};
    _profileCache[id] = merged;
    return Map<String, dynamic>.from(merged);
  }

  Future<Map<String, dynamic>?> myProfile() async => profile(_userId);

  Future<void> createKnock(String receiverId, {String? intro}) =>
      _serializeUsage(() async {
        await _assertLocalAllowance(DailyUsageAction.knock);
        try {
          final result = await _supabase.rpc(
            'send_knock',
            params: {'target_user_id': receiverId},
          );
          await _handleLimitResult(result, action: DailyUsageAction.knock);
          await _recordSuccessfulUsage(result, DailyUsageAction.knock);
        } on PostgrestException catch (e) {
          final duplicatePendingKnock =
              e.code == '23505' ||
              e.message.contains('unique_pending_knock') ||
              e.message.contains('already exists');
          if (duplicatePendingKnock) return;
          rethrow;
        }
      });

  Future<List<Map<String, dynamic>>> incomingKnocks() async {
    final rows = await _supabase
        .from('knocks')
        .select('id, sender_id, status, created_at')
        .eq('receiver_id', _userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return _addKnockProfiles(
      List<Map<String, dynamic>>.from(rows as List),
      idKey: 'sender_id',
      profileKey: 'sender',
    );
  }

  Future<List<Map<String, dynamic>>> sentKnocks() async {
    final rows = await _supabase
        .from('knocks')
        .select('id, receiver_id, status, created_at')
        .eq('sender_id', _userId)
        .order('created_at', ascending: false);
    return _addKnockProfiles(
      List<Map<String, dynamic>>.from(rows as List),
      idKey: 'receiver_id',
      profileKey: 'receiver',
    );
  }

  Future<List<Map<String, dynamic>>> _addKnockProfiles(
    List<Map<String, dynamic>> rows, {
    required String idKey,
    required String profileKey,
  }) async {
    final ids = rows
        .map((row) => row[idKey])
        .whereType<String>()
        .toSet()
        .toList();
    if (ids.isEmpty) return rows;

    final profileRows = await _supabase
        .from('profiles')
        .select(
          'id, public_name, age, public_city, public_country_code, verification_status, profile_photos(id, public_url, is_primary, sort_order)',
        )
        .inFilter('id', ids);
    final profilesById = {
      for (final profile in List<Map<String, dynamic>>.from(
        profileRows as List,
      ))
        profile['id'] as String: profile,
    };

    for (final row in rows) {
      row[profileKey] = profilesById[row[idKey]] ?? <String, dynamic>{};
    }
    return rows;
  }

  Future<String> acceptKnock(String knockId) async {
    final result = await _supabase.rpc(
      'approve_knock',
      params: {'knock_id': knockId},
    );
    if (result is Map && result['conversation_id'] != null) {
      return result['conversation_id'].toString();
    }
    return result.toString();
  }

  Future<void> declineKnock(String knockId) async {
    await _supabase.rpc('decline_knock', params: {'knock_id': knockId});
  }

  Future<void> createChatRequest(String receiverId, String introduction) =>
      _serializeUsage(() async {
        await _assertLocalAllowance(DailyUsageAction.chatRequest);
        try {
          final result = await _supabase.rpc(
            'create_chat_request',
            params: {
              'target_user_id': receiverId,
              'introduction_text': introduction,
            },
          );
          await _handleLimitResult(
            result,
            action: DailyUsageAction.chatRequest,
          );
          await _recordSuccessfulUsage(result, DailyUsageAction.chatRequest);
        } on PostgrestException catch (e) {
          final duplicatePendingRequest =
              e.code == '23505' ||
              e.message.contains('unique_pending_chat_request') ||
              e.message.contains('already exists');
          if (duplicatePendingRequest) return;
          rethrow;
        }
      });

  Future<T> _serializeUsage<T>(Future<T> Function() operation) {
    final previous = _usageQueue;
    final completer = Completer<T>();
    _usageQueue = () async {
      try {
        await previous;
      } catch (_) {}
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    }();
    return completer.future;
  }

  int _limitFor(DailyUsageAction action) =>
      action == DailyUsageAction.knock ? _knockLimit : _chatLimit;

  String get _usageDay {
    final now = DateTime.now().toUtc();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String _usageKey(DailyUsageAction action) =>
      'daily_usage_${_userId}_${_usageDay}_${action.name}';

  Future<int> _localUsed(DailyUsageAction action) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_usageKey(action)) ?? 0;
  }

  Future<void> _saveLocalUsed(DailyUsageAction action, int used) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_usageKey(action), used.clamp(0, _limitFor(action)));
  }

  void _publishUsage(DailyUsageAction action, int used) {
    final limit = _limitFor(action);
    final safeUsed = used.clamp(0, limit);
    dailyUsageChanged.value = DailyUsageChange(
      action: action,
      used: safeUsed,
      remaining: limit - safeUsed,
      limit: limit,
    );
  }

  Future<bool> _hasActivePremium() async {
    try {
      final rows = await _supabase
          .from('subscriptions')
          .select('id')
          .eq('user_id', _userId)
          .eq('status', 'active')
          .eq('entitlement', 'premium')
          .gt('current_period_end', DateTime.now().toUtc().toIso8601String())
          .limit(1);
      return (rows as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _assertLocalAllowance(DailyUsageAction action) async {
    final usage = await dailyUsage();
    final used = action == DailyUsageAction.knock
        ? usage['knocks_sent'] ?? 0
        : usage['chat_requests_sent'] ?? 0;
    final limit = _limitFor(action);
    if (used < limit || await _hasActivePremium()) return;
    _publishUsage(action, limit);
    throw DailyActionLimitException(
      action: action == DailyUsageAction.knock ? 'knock' : 'chat request',
      limit: limit,
      sent: limit,
    );
  }

  Future<void> _handleLimitResult(
    dynamic result, {
    required DailyUsageAction action,
  }) async {
    if (result is! Map || result['success'] != false) return;
    if (result['error'] != 'DAILY_LIMIT_EXCEEDED') {
      throw StateError(result['error']?.toString() ?? 'Request failed');
    }
    final limit = (result['limit'] as num?)?.toInt() ?? _limitFor(action);
    final sent = (result['sent'] as num?)?.toInt() ?? limit;
    await _saveLocalUsed(action, sent);
    _publishUsage(action, sent);
    throw DailyActionLimitException(
      action: action == DailyUsageAction.knock ? 'knock' : 'chat request',
      limit: limit,
      sent: sent,
    );
  }

  Future<void> _recordSuccessfulUsage(
    dynamic result,
    DailyUsageAction action,
  ) async {
    if (result is Map &&
        (result['duplicate'] == true || result['consumed'] == false)) {
      return;
    }
    if (result is Map && result['premium'] == true) return;
    final limit = _limitFor(action);
    final current = await _localUsed(action);
    final remaining = result is Map
        ? (result['remaining'] as num?)?.toInt()
        : null;
    final serverUsed = remaining != null && remaining >= 0
        ? limit - remaining
        : 0;
    final used = (current + 1) > serverUsed ? current + 1 : serverUsed;
    await _saveLocalUsed(action, used);
    _publishUsage(action, used);
  }

  Future<Map<String, int>> dailyUsage() async {
    var serverKnocks = 0;
    var serverChats = 0;
    try {
      final result = await _supabase.rpc('get_my_daily_usage');
      if (result is Map) {
        serverKnocks = (result['knocks_sent'] as num?)?.toInt() ?? 0;
        serverChats = (result['chat_requests_sent'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {
      try {
        final row = await _supabase
            .from('daily_usage')
            .select('knocks_sent, chat_requests_sent')
            .eq('user_id', _userId)
            .eq('usage_date', _usageDay)
            .maybeSingle();
        serverKnocks = (row?['knocks_sent'] as num?)?.toInt() ?? 0;
        serverChats = (row?['chat_requests_sent'] as num?)?.toInt() ?? 0;
      } catch (_) {}
    }

    final start = '${_usageDay}T00:00:00.000Z';
    final activity = await Future.wait([
      _countToday('knocks', start),
      _countToday('chat_requests', start),
      _countToday('messages', start),
    ]);
    final localKnocks = await _localUsed(DailyUsageAction.knock);
    final localChats = await _localUsed(DailyUsageAction.chatRequest);
    final knocks = [
      serverKnocks,
      activity[0],
      localKnocks,
    ].reduce((a, b) => a > b ? a : b);
    final chats = [
      serverChats,
      activity[1] + activity[2],
      localChats,
    ].reduce((a, b) => a > b ? a : b);
    await _saveLocalUsed(DailyUsageAction.knock, knocks);
    await _saveLocalUsed(DailyUsageAction.chatRequest, chats);
    return {
      'knocks_sent': knocks.clamp(0, _knockLimit),
      'chat_requests_sent': chats.clamp(0, _chatLimit),
      'knock_limit': _knockLimit,
      'chat_limit': _chatLimit,
    };
  }

  Future<int> _countToday(String table, String start) async {
    try {
      final rows = await _supabase
          .from(table)
          .select('id')
          .eq('sender_id', _userId)
          .gte('created_at', start);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> incomingChatRequests() async {
    final rows = await _supabase
        .from('chat_requests')
        .select('id, sender_id, introduction, status, created_at')
        .eq('receiver_id', _userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return _addKnockProfiles(
      List<Map<String, dynamic>>.from(rows as List),
      idKey: 'sender_id',
      profileKey: 'sender',
    );
  }

  Future<List<Map<String, dynamic>>> sentChatRequests() async {
    final rows = await _supabase
        .from('chat_requests')
        .select('id, receiver_id, introduction, status, created_at')
        .eq('sender_id', _userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return _addKnockProfiles(
      List<Map<String, dynamic>>.from(rows as List),
      idKey: 'receiver_id',
      profileKey: 'receiver',
    );
  }

  Future<String> acceptChatRequest(String requestId) async {
    final result = await _supabase.rpc(
      'accept_chat_request',
      params: {'request_id': requestId},
    );
    if (result is Map && result['conversation_id'] != null) {
      return result['conversation_id'].toString();
    }
    return result.toString();
  }

  Future<void> declineChatRequest(String requestId) async {
    await _supabase.rpc(
      'decline_chat_request',
      params: {'request_id': requestId},
    );
  }

  Future<String> getOrCreateConversation(String otherUserId) async {
    final id = await _supabase.rpc(
      'get_or_create_conversation',
      params: {'other_user_id': otherUserId},
    );
    return id.toString();
  }

  Future<List<Map<String, dynamic>>> conversations() async {
    final rows = await _supabase
        .from('conversations')
        .select(
          'id, participant_a, participant_b, updated_at, last_message_at, a:profiles!conversations_participant_a_fkey(id, public_name, age, public_country_code, last_seen_at, verification_status, profile_photos(id, public_url, is_primary, sort_order)), b:profiles!conversations_participant_b_fkey(id, public_name, age, public_country_code, last_seen_at, verification_status, profile_photos(id, public_url, is_primary, sort_order)), messages(body, sender_id, read_at, created_at)',
        )
        .or('participant_a.eq.$_userId,participant_b.eq.$_userId')
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> messages(String conversationId) async {
    try {
      final rows = await _supabase
          .from('messages')
          .select('id, sender_id, body, created_at, delivered_at, read_at')
          .eq('conversation_id', conversationId)
          .order('created_at');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (_) {
      final rows = await _supabase
          .from('messages')
          .select('id, sender_id, body, created_at, read_at')
          .eq('conversation_id', conversationId)
          .order('created_at');
      return List<Map<String, dynamic>>.from(rows as List).map((row) {
        row['delivered_at'] = row['created_at'];
        return row;
      }).toList();
    }
  }

  Future<void> markConversationMessagesSeen(String conversationId) async {
    try {
      await _supabase.rpc(
        'mark_conversation_messages_seen',
        params: {'conversation': conversationId},
      );
    } catch (_) {
      // The delivery-status migration may not be deployed yet.
    }
  }

  Future<Map<String, dynamic>?> conversationPartner(
    String conversationId,
  ) async {
    final c = await _supabase
        .from('conversations')
        .select(
          'participant_a, participant_b, a:profiles!conversations_participant_a_fkey(id, public_name, age, public_country_code, last_seen_at, verification_status, profile_photos(id, public_url, is_primary, sort_order)), b:profiles!conversations_participant_b_fkey(id, public_name, age, public_country_code, last_seen_at, verification_status, profile_photos(id, public_url, is_primary, sort_order))',
        )
        .eq('id', conversationId)
        .maybeSingle();
    if (c == null) return null;
    return c['participant_a'] == _userId
        ? c['b'] as Map<String, dynamic>?
        : c['a'] as Map<String, dynamic>?;
  }

  Future<void> sendMessage(String conversationId, String body) =>
      _serializeUsage(() async {
        await _assertLocalAllowance(DailyUsageAction.chatRequest);
        final result = await _supabase.rpc(
          'send_message',
          params: {'conversation': conversationId, 'body': body},
        );
        await _handleLimitResult(result, action: DailyUsageAction.chatRequest);
        await _recordSuccessfulUsage(result, DailyUsageAction.chatRequest);
      });

  Future<List<Map<String, dynamic>>> notifications() async {
    final rows = await _supabase
        .from('notifications')
        .select('id, user_id, type, title, body, data, is_read, created_at')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> markNotificationRead(String id) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> markAllNotificationsRead() async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _userId)
        .eq('is_read', false);
  }

  Future<Map<String, dynamic>> profileInteractionStatus(
    String targetUserId,
  ) async {
    try {
      final knockCount = await _supabase
          .from('knocks')
          .select('id')
          .eq('sender_id', _userId)
          .eq('receiver_id', targetUserId)
          .inFilter('status', ['pending', 'approved'])
          .limit(1);

      final chatRequestCount = await _supabase
          .from('chat_requests')
          .select('id')
          .eq('sender_id', _userId)
          .eq('receiver_id', targetUserId)
          .inFilter('status', ['pending', 'accepted'])
          .limit(1);

      return {
        'knocked': (knockCount as List).isNotEmpty,
        'chat_requested': (chatRequestCount as List).isNotEmpty,
      };
    } catch (_) {
      return {'knocked': false, 'chat_requested': false};
    }
  }

  Future<Map<String, List<String>>> feedInteractionStatuses() async {
    try {
      final knocks = await _supabase
          .from('knocks')
          .select('receiver_id')
          .eq('sender_id', _userId)
          .inFilter('status', ['pending', 'approved']);

      final chatRequests = await _supabase
          .from('chat_requests')
          .select('receiver_id')
          .eq('sender_id', _userId)
          .inFilter('status', ['pending', 'accepted']);

      final knockedIds = (knocks as List)
          .map((row) => row['receiver_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      final chatRequestedIds = (chatRequests as List)
          .map((row) => row['receiver_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      return {'knocked': knockedIds, 'chat_requested': chatRequestedIds};
    } catch (_) {
      return {'knocked': [], 'chat_requested': []};
    }
  }

  String photoUrl(Map<String, dynamic>? row) {
    final photos = row?['profile_photos'];
    if (photos is Map) {
      final url = photos['public_url'];
      if (url is String && url.isNotEmpty) return url;
    }
    if (photos is List && photos.isNotEmpty) {
      photos.sort((a, b) {
        final ap = a['is_primary'] == true ? 0 : 1;
        final bp = b['is_primary'] == true ? 0 : 1;
        if (ap != bp) return ap.compareTo(bp);
        return 0;
      });
      final url = photos.first['public_url'];
      if (url is String && url.isNotEmpty) return url;
    }
    return 'https://ui-avatars.com/api/?background=5E0B24&color=fff&name=${Uri.encodeComponent((row?['public_name'] ?? 'Loverage').toString())}';
  }
}
