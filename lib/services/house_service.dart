import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class HouseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<Map<String, dynamic>> createHouse({required String name}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final inviteCode = _generateInviteCode();

    // 1. Create the house
    final houseResponse = await _supabase
        .from('houses')
        .insert({
          'name': name,
          'created_by': user.id,
          'invite_code': inviteCode,
        })
        .select()
        .single();

    // 2. Add user to house_members
    try {
      await _supabase.from('house_members').insert({
        'house_id': houseResponse['id'],
        'user_id': user.id,
        'role': 'head',
      });
    } catch (e) {
      print('Error adding member: $e');
    }

    return houseResponse;
  }

  Future<Map<String, dynamic>> joinHouse({required String inviteCode}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Verify house exists by invite code
    final house = await _supabase
        .from('houses')
        .select()
        .eq('invite_code', inviteCode)
        .single();

    // Add to members
    await _supabase.from('house_members').insert({
      'house_id': house['id'],
      'user_id': user.id,
      'role': 'member',
    });

    return house;
  }

  Future<Map<String, dynamic>?> getCurrentHouse() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final memberData = await _supabase
          .from('house_members')
          .select('house_id, houses(*)')
          .eq('user_id', user.id)
          .maybeSingle();

      if (memberData != null && memberData['houses'] != null) {
        return memberData['houses'] as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching house: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getHouseMembers(String houseId) async {
    try {
      // 1. Get members
      final membersResponse = await _supabase
          .from('house_members')
          .select('user_id, role, joined_at')
          .eq('house_id', houseId);

      final members = List<Map<String, dynamic>>.from(membersResponse);

      if (members.isEmpty) return [];

      // 2. Get user IDs
      final userIds = members.map((m) => m['user_id'] as String).toList();

      // 3. Get profiles
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, full_name, email, avatar_url')
          .filter('id', 'in', userIds);

      final profiles = List<Map<String, dynamic>>.from(profilesResponse);

      // 4. Merge
      // Create a map of id -> profile for faster lookup
      final profilesMap = {for (var p in profiles) p['id']: p};

      return members.map((member) {
        final userId = member['user_id'];
        final profile = profilesMap[userId];

        return {
          ...member,
          'profiles': profile, // Nest it so the UI code works
        };
      }).toList();
    } catch (e) {
      print('Error fetching members: $e');
      return [];
    }
  }

  Future<void> leaveHouse(String houseId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase
        .from('house_members')
        .delete()
        .eq('house_id', houseId)
        .eq('user_id', user.id);
  }

  Future<void> deleteHouse(String houseId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final role = await _getMemberRole(houseId, user.id);

    if (role != 'head') {
      throw Exception('Only the Head of House can delete the house');
    }

    // Delete all members first to ensure clean deletion
    await _supabase.from('house_members').delete().eq('house_id', houseId);

    // Then delete the house
    await _supabase.from('houses').delete().eq('id', houseId);
  }

  Future<void> kickMember(String houseId, String userId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    final requesterRole = await _getMemberRole(houseId, currentUser.id);
    final targetRole = await _getMemberRole(houseId, userId);

    _validateKickPermissions(requesterRole, targetRole);

    await _supabase
        .from('house_members')
        .delete()
        .eq('house_id', houseId)
        .eq('user_id', userId);
  }

  void _validateKickPermissions(String requesterRole, String targetRole) {
    final isAuthorized = requesterRole == 'admin' || requesterRole == 'head';
    if (!isAuthorized) {
      throw Exception('Only admins or the head can kick members');
    }

    if (requesterRole == 'admin') {
      if (targetRole == 'admin' || targetRole == 'head') {
        throw Exception('Admins cannot kick other admins or the head');
      }
    }
  }

  Future<void> promoteToAdmin(String houseId, String userId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    final requesterRole = await _getMemberRole(houseId, currentUser.id);

    if (requesterRole != 'admin' && requesterRole != 'head') {
      throw Exception('Only admins or the head can promote members');
    }

    await _supabase
        .from('house_members')
        .update({'role': 'admin'})
        .eq('house_id', houseId)
        .eq('user_id', userId);
  }

  Future<void> transferHeadRole(String houseId, String newHeadId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    final requesterRole = await _getMemberRole(houseId, currentUser.id);

    if (requesterRole != 'head') {
      throw Exception('Only the Head of House can transfer the role');
    }

    // Update house created_by (for consistency)
    await _supabase
        .from('houses')
        .update({'created_by': newHeadId})
        .eq('id', houseId);

    // Demote current head to admin
    await _supabase
        .from('house_members')
        .update({'role': 'admin'})
        .eq('house_id', houseId)
        .eq('user_id', currentUser.id);

    // Promote new head to head
    await _supabase
        .from('house_members')
        .update({'role': 'head'})
        .eq('house_id', houseId)
        .eq('user_id', newHeadId);
  }

  Future<String> _getMemberRole(String houseId, String userId) async {
    final response = await _supabase
        .from('house_members')
        .select('role')
        .eq('house_id', houseId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) throw Exception('Member not found in house');
    return response['role'] as String;
  }
}
