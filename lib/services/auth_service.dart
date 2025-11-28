import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> updateProfile({String? name, String? avatarUrl}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (name != null) updates['full_name'] = name;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isEmpty) return;

    // Update auth metadata
    await _supabase.auth.updateUser(UserAttributes(data: updates));

    // Update profiles table
    await _supabase.from('profiles').update(updates).eq('id', user.id);
  }

  Future<void> deleteAccount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Delete from profiles (cascade should handle house_members)
    // Note: Supabase Auth deletion usually requires using the admin API or a specific Edge Function
    // if you want to delete the actual Auth User from the client side without specific configuration.
    // However, for this project, we'll assume we can delete the profile and the user.
    // Actually, client-side user deletion is often restricted.
    // We will try to call a function or just delete data.

    // For now, let's just sign out as "deletion" if we can't delete the auth user directly.
    // But we can delete the profile data.

    // await _supabase.from('profiles').delete().eq('id', user.id); // Cascade handled by DB

    // To actually delete the user, we might need an RPC or just accept that we delete their data.
    // Let's try to delete the user via RPC if you have one, otherwise just sign out.
    // Since I don't have the admin key, I can't delete from auth.users easily from client unless enabled.

    // Let's just delete the profile and sign out for now, which effectively "deletes" them from the app's view.
    await _supabase.from('profiles').delete().eq('id', user.id);
    await signOut();
  }
}
