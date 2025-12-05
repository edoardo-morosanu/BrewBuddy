class DrinkItem {
  const DrinkItem({
    required this.id,
    required this.barcode,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.addedBy,
    required this.category,
    required this.lowStock,
    this.imageUrl,
    this.history = const [],
  });

  final String id;
  final String barcode;
  final String name;
  final int quantity;
  final String unit;
  final String addedBy;
  final String category;
  final bool lowStock;
  final String? imageUrl;
  final List<HistoryEntry> history;
}

class HistoryEntry {
  const HistoryEntry({
    required this.date,
    required this.action,
    required this.user,
    required this.amount,
    this.note,
  });

  final DateTime date;
  final HistoryAction action;
  final String user;
  final int amount;
  final String? note;
}

enum HistoryAction { added, removed, restocked, adjusted }
