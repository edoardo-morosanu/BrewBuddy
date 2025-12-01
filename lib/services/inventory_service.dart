import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch product by barcode for a specific house
  Future<Map<String, dynamic>?> getProductByBarcode(
    String houseId,
    String barcode,
  ) async {
    try {
      final response = await _supabase
          .from('inventory_items')
          .select()
          .eq('house_id', houseId)
          .eq('barcode', barcode)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  // Add or update product
  Future<void> addOrUpdateProduct({
    required String houseId,
    required String barcode,
    required String name,
    required int quantityChange,
    String? imageUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Check if exists
    final existing = await getProductByBarcode(houseId, barcode);

    if (existing != null) {
      // Update
      final currentQty = (existing['quantity'] as int);
      final newQuantity = currentQty + quantityChange;
      final actualNewQuantity = newQuantity < 0 ? 0 : newQuantity;
      final actualChange = actualNewQuantity - currentQty;

      await _supabase
          .from('inventory_items')
          .update({
            'quantity': actualNewQuantity,
            'product_name': name, // Update name if user changed it
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing['id']);

      // Record history
      if (actualChange != 0) {
        await _supabase.from('inventory_history').insert({
          'inventory_item_id': existing['id'],
          'user_id': user.id,
          'action': actualChange > 0 ? 'restocked' : 'removed',
          'amount': actualChange.abs(),
          'note': actualChange > 0 ? 'Restocked via scan' : 'Consumed',
        });
      }
    } else {
      // Insert
      if (quantityChange <= 0) return; // Can't remove if doesn't exist

      final newItem = await _supabase
          .from('inventory_items')
          .insert({
            'house_id': houseId,
            'barcode': barcode,
            'product_name': name,
            'quantity': quantityChange,
            'image_url': imageUrl,
            'created_by': user.id,
          })
          .select()
          .single();

      // Record history
      await _supabase.from('inventory_history').insert({
        'inventory_item_id': newItem['id'],
        'user_id': user.id,
        'action': 'added',
        'amount': quantityChange,
        'note': 'Initial stock',
      });
    }
  }

  // Get all inventory items for a house
  Future<List<Map<String, dynamic>>> getInventory(String houseId) async {
    try {
      final response = await _supabase
          .from('inventory_items')
          .select('*, inventory_history(*)')
          .eq('house_id', houseId)
          .order('product_name', ascending: true)
          .order(
            'created_at',
            referencedTable: 'inventory_history',
            ascending: false,
          );

      final items = List<Map<String, dynamic>>.from(response);

      // Collect user IDs to fetch profiles
      final userIds = <String>{};
      for (final item in items) {
        // Add item creator
        if (item['created_by'] != null) {
          userIds.add(item['created_by'].toString());
        }

        final history = item['inventory_history'] as List<dynamic>?;
        if (history != null) {
          for (final entry in history) {
            if (entry['user_id'] != null) {
              userIds.add(entry['user_id'].toString());
            }
          }
        }
      }

      if (userIds.isNotEmpty) {
        final profiles = await _supabase
            .from('profiles')
            .select('id, full_name')
            .filter('id', 'in', userIds.toList());

        final profilesMap = {for (var p in profiles) p['id']: p};

        // Attach profiles to items and history entries
        for (final item in items) {
          // Attach creator profile to item
          final creatorId = item['created_by'];
          if (creatorId != null && profilesMap.containsKey(creatorId)) {
            item['creator_profile'] = profilesMap[creatorId];
          }

          final history = item['inventory_history'] as List<dynamic>?;
          if (history != null) {
            for (final entry in history) {
              final userId = entry['user_id'];
              if (userId != null && profilesMap.containsKey(userId)) {
                entry['profiles'] = profilesMap[userId];
              }
            }
          }
        }
      }

      return items;
    } catch (e) {
      print('Error fetching inventory: $e');
      return [];
    }
  }
}
