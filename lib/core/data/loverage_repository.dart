import 'package:supabase_flutter/supabase_flutter.dart';

class LoverageRepository {
  LoverageRepository(this._supabase);
  final SupabaseClient _supabase;

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw Exception('You must be signed in.');
    return id;
  }

  Future<List<Map<String, dynamic>>> feedProfiles({
    String filter = 'All',
  }) async {
    var query = _supabase
        .from('profiles')
        .select(
          'id, public_name, age, public_city, public_country_code, profession, bio, traits, verification_status, is_premium, last_seen_at, created_at, profile_photos(public_url, is_primary, sort_order)',
        )
        .eq('profile_status', 'active')
        .eq('verification_status', 'approved')
        .eq('is_hidden', false)
        .neq('id', _userId);

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

    final rows = await query.order('last_seen_at', ascending: false).limit(60);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, dynamic>?> profile(String id) async {
    final row = await _supabase
        .from('profiles')
        .select(
          'id, public_name, age, public_city, public_country_code, profession, education, languages, religion, bio, traits, verification_status, is_premium, last_seen_at, profile_photos(public_url, is_primary, sort_order)',
        )
        .eq('id', id)
        .maybeSingle();
    return row;
  }

  Future<Map<String, dynamic>?> myProfile() async => profile(_userId);

  Future<void> createKnock(String receiverId, {String? intro}) async {
    await _supabase.rpc(
      'create_knock',
      params: {'receiver': receiverId, 'intro': intro},
    );
  }

  Future<List<Map<String, dynamic>>> incomingKnocks() async {
    final rows = await _supabase
        .from('knocks')
        .select(
          'id, message, status, created_at, sender:profiles!knocks_sender_id_fkey(id, public_name, age, public_city, public_country_code, verification_status, profile_photos(public_url, is_primary, sort_order))',
        )
        .eq('receiver_id', _userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> sentKnocks() async {
    final rows = await _supabase
        .from('knocks')
        .select(
          'id, message, status, created_at, receiver:profiles!knocks_receiver_id_fkey(id, public_name, age, public_city, public_country_code, verification_status, profile_photos(public_url, is_primary, sort_order))',
        )
        .eq('sender_id', _userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<String> acceptKnock(String knockId) async {
    final id = await _supabase.rpc(
      'accept_knock',
      params: {'knock_id': knockId},
    );
    return id.toString();
  }

  Future<void> declineKnock(String knockId) async {
    await _supabase.rpc('decline_knock', params: {'knock_id': knockId});
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
          'id, participant_a, participant_b, updated_at, last_message_at, a:profiles!conversations_participant_a_fkey(id, public_name, age, public_country_code, last_seen_at, verification_status, profile_photos(public_url, is_primary, sort_order)), b:profiles!conversations_participant_b_fkey(id, public_name, age, public_country_code, last_seen_at, verification_status, profile_photos(public_url, is_primary, sort_order)), messages(body, sender_id, read_at, created_at)',
        )
        .or('participant_a.eq.$_userId,participant_b.eq.$_userId')
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> messages(String conversationId) async {
    final rows = await _supabase
        .from('messages')
        .select('id, sender_id, body, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, dynamic>?> conversationPartner(
    String conversationId,
  ) async {
    final c = await _supabase
        .from('conversations')
        .select(
          'participant_a, participant_b, a:profiles!conversations_participant_a_fkey(id, public_name, age, public_country_code, last_seen_at, verification_status, profile_photos(public_url, is_primary, sort_order)), b:profiles!conversations_participant_b_fkey(id, public_name, age, public_country_code, last_seen_at, verification_status, profile_photos(public_url, is_primary, sort_order))',
        )
        .eq('id', conversationId)
        .maybeSingle();
    if (c == null) return null;
    return c['participant_a'] == _userId
        ? c['b'] as Map<String, dynamic>?
        : c['a'] as Map<String, dynamic>?;
  }

  Future<void> sendMessage(String conversationId, String body) async {
    await _supabase.rpc(
      'send_message',
      params: {'conversation': conversationId, 'body': body},
    );
  }

  Future<List<Map<String, dynamic>>> notifications() async {
    final rows = await _supabase
        .from('notifications')
        .select('id, type, title, body, route_path, read_at, created_at')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> markNotificationRead(String id) async {
    await _supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> markAllNotificationsRead() async {
    await _supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', _userId)
        .filter('read_at', 'is', null);
  }

  String photoUrl(Map<String, dynamic>? row) {
    final photos = row?['profile_photos'];
    if (photos is List && photos.isNotEmpty) {
      photos.sort((a, b) {
        final ap = a['is_primary'] == true ? 0 : 1;
        final bp = b['is_primary'] == true ? 0 : 1;
        if (ap != bp) return ap.compareTo(bp);
        return ((a['sort_order'] ?? 0) as num).compareTo(
          (b['sort_order'] ?? 0) as num,
        );
      });
      final url = photos.first['public_url'];
      if (url is String && url.isNotEmpty) return url;
    }
    return 'https://ui-avatars.com/api/?background=5E0B24&color=fff&name=${Uri.encodeComponent((row?['public_name'] ?? 'Loverage').toString())}';
  }
}
