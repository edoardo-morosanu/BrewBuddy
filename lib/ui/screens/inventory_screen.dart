import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:brewbuddy/utils/responsive.dart';
import 'package:brewbuddy/services/inventory_service.dart';
import 'package:brewbuddy/services/house_service.dart';

import '../../models/drink_item.dart';
import 'barcode_scanner_screen.dart';
import 'drink_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, this.isInMainScreen = false});

  final bool isInMainScreen;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fabController;
  final InventoryService _inventoryService = InventoryService();
  final HouseService _houseService = HouseService();
  final TextEditingController _searchController = TextEditingController();

  bool _hasAnimated = false;
  bool _showOnlyLowStock = false;
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _houseId;
  List<DrinkItem> _drinks = [];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    _loadData();

    // Animate FAB in after a short delay, only on first visit
    if (!_hasAnimated) {
      _hasAnimated = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _fabController.forward();
        }
      });
    } else {
      // Skip animation, go to end state
      _fabController.value = 1.0;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final house = await _houseService.getCurrentHouse();
      if (house != null) {
        _houseId = house['id']?.toString();
        await _refreshInventory();
      } else {
        // Handle case where user is not in a house
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You are not in a house. Please join or create one.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading inventory: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshInventory() async {
    if (_houseId == null) return;
    try {
      final items = await _inventoryService.getInventory(_houseId!);
      if (mounted) {
        setState(() {
          _drinks = items.map((item) {
            final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
            return DrinkItem(
              id: item['id']?.toString() ?? '',
              barcode: item['barcode']?.toString() ?? '',
              name: item['product_name']?.toString() ?? 'Unknown',
              quantity: quantity,
              unit: 'units', // Default unit for now
              addedBy:
                  item['creator_profile']?['full_name']?.toString() ??
                  'Unknown',
              category: 'Drink', // Placeholder or infer from name?
              lowStock: quantity < 5,
              imageUrl: item['image_url']?.toString(),
              history:
                  (item['inventory_history'] as List<dynamic>?)?.map((h) {
                    final actionStr = h['action']?.toString() ?? 'added';
                    HistoryAction action;
                    switch (actionStr) {
                      case 'removed':
                        action = HistoryAction.removed;
                        break;
                      case 'restocked':
                        action = HistoryAction.restocked;
                        break;
                      case 'adjusted':
                        action = HistoryAction.adjusted;
                        break;
                      default:
                        action = HistoryAction.added;
                    }

                    final profile = h['profiles'] as Map<String, dynamic>?;
                    final userName =
                        profile?['full_name']?.toString() ?? 'Unknown User';

                    return HistoryEntry(
                      date: DateTime.parse(h['created_at']),
                      action: action,
                      user: userName,
                      amount: (h['amount'] as num?)?.toInt() ?? 0,
                      note: h['note']?.toString(),
                    );
                  }).toList() ??
                  [],
            );
          }).toList();
        });
      }
    } catch (e) {
      print('Error refreshing inventory: $e');
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScanBarcode() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
        fullscreenDialog: true,
      ),
    );
    // Refresh after returning from scanner
    _refreshInventory();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _refreshInventory,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(colorScheme, textTheme),
            _buildStatsSection(colorScheme, textTheme),
            _buildDrinksList(colorScheme, textTheme),
          ],
        ),
      ),
      floatingActionButton: _buildScanButton(colorScheme),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme, TextTheme textTheme) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      pinned: false,
      backgroundColor: colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16, right: 24),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search drinks...',
                  border: InputBorder.none,
                  hintStyle: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              )
            : Text(
                'Inventory',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
              }
            });
          },
          icon: Icon(
            _isSearching ? Icons.close_rounded : Icons.search_rounded,
            size: 24,
          ),
          style: IconButton.styleFrom(
            fixedSize: const Size(48, 48),
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildStatsSection(ColorScheme colorScheme, TextTheme textTheme) {
    final totalDrinks = _drinks.fold<int>(
      0,
      (sum, drink) => sum + drink.quantity,
    );
    final lowStockCount = _drinks.where((d) => d.lowStock).length;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.maxContentWidth),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.inventory_2_rounded,

                    label: 'Total Items',

                    value: '$totalDrinks',

                    colorScheme: colorScheme,

                    textTheme: textTheme,

                    accentColor: colorScheme.primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showOnlyLowStock = !_showOnlyLowStock;
                      });
                    },
                    child: _StatCard(
                      icon: Icons.warning_amber_rounded,

                      label: 'Low Stock',

                      value: '$lowStockCount',

                      colorScheme: colorScheme,

                      textTheme: textTheme,

                      accentColor: colorScheme.error,

                      isActive: _showOnlyLowStock,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrinksList(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final displayDrinks = _showOnlyLowStock
        ? _drinks.where((d) => d.lowStock).toList()
        : _drinks;

    // Apply search filter
    final filteredDrinks = _searchQuery.isEmpty
        ? displayDrinks
        : displayDrinks
              .where((d) => d.name.toLowerCase().contains(_searchQuery))
              .toList();

    if (filteredDrinks.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.inventory_2_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No results found'
                    : _showOnlyLowStock
                    ? 'No low stock items'
                    : 'No drinks yet',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try searching for something else'
                    : _showOnlyLowStock
                    ? 'All items are well stocked!'
                    : 'Scan a barcode to add your first drink',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final drink = filteredDrinks[index];

          // Skip animations after first visit
          if (_hasAnimated) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DrinkCard(
                drink: drink,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            );
          }

          // Animate on first visit
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DrinkCard(
                      drink: drink,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  ),
                ),
              );
            },
          );
        }, childCount: filteredDrinks.length),
      ),
    );
  }

  Widget _buildScanButton(ColorScheme colorScheme) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _handleScanBarcode,
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 28),
          label: const Text(
            'Scan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          heroTag: 'inventory_scan_fab',

          extendedPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
    required this.accentColor,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final Color accentColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive
                ? accentColor.withValues(alpha: 0.15)
                : colorScheme.surfaceContainerHigh.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? accentColor.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
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
}

class _DrinkCard extends StatelessWidget {
  const _DrinkCard({
    required this.drink,
    required this.colorScheme,
    required this.textTheme,
  });

  final DrinkItem drink;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: drink.lowStock
                  ? colorScheme.error.withValues(alpha: 0.3)
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: drink.lowStock ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DrinkDetailScreen(drink: drink),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildDrinkIcon(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  drink.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (drink.lowStock)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 14,
                                        color: colorScheme.error,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Low',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.error,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  drink.category,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${drink.quantity}',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          drink.unit,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrinkIcon() {
    if (drink.imageUrl != null && drink.imageUrl!.isNotEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: colorScheme.surfaceContainerHighest,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            drink.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
          ),
        ),
      );
    }
    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(_getCategoryIcon(), size: 28, color: colorScheme.primary),
    );
  }

  IconData _getCategoryIcon() {
    switch (drink.category.toLowerCase()) {
      case 'beer':
        return Icons.sports_bar_rounded;
      case 'soda':
        return Icons.local_drink_rounded;
      case 'juice':
        return Icons.blender_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      default:
        return Icons.local_cafe_rounded;
    }
  }
}
