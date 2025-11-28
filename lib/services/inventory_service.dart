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
      final newQuantity = (existing['quantity'] as int) + quantityChange;
      await _supabase
          .from('inventory_items')
          .update({
            'quantity': newQuantity < 0 ? 0 : newQuantity,
            'product_name': name, // Update name if user changed it
            'updated_at': DateTime.now().toIso8601String(),
            // 'last_updated_by': user.id, // Optional tracking
          })
          .eq('id', existing['id']);
    } else {
      // Insert
      if (quantityChange < 0) return; // Can't remove if doesn't exist

      await _supabase.from('inventory_items').insert({
        'house_id': houseId,
        'barcode': barcode,
        'product_name': name,
        'quantity': quantityChange,
        'image_url': imageUrl,
        'created_by': user.id,
      });
    }
  }

  // Get all inventory items for a house
  Future<List<Map<String, dynamic>>> getInventory(String houseId) async {
    try {
      final response = await _supabase
          .from('inventory_items')
          .select()
          .eq('house_id', houseId)
          .order('product_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching inventory: $e');
      return [];
    }
  }
}
