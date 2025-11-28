import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:brewbuddy/utils/responsive.dart';

class DrinkDetailScreen extends StatefulWidget {
  const DrinkDetailScreen({
    super.key,
    required this.drinkName,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.lowStock,
  });

  final String drinkName;
  final int quantity;
  final String unit;
  final String category;
  final bool lowStock;

  @override
  State<DrinkDetailScreen> createState() => _DrinkDetailScreenState();
}

class _DrinkDetailScreenState extends State<DrinkDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Mock history data
  final List<_HistoryItem> _history = [
    _HistoryItem(
      action: 'Added',
      quantity: 5,
      unit: 'bottles',
      user: 'John Doe',
      avatar: '👨',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    _HistoryItem(
      action: 'Consumed',
      quantity: 2,
      unit: 'bottles',
      user: 'Sarah Smith',
      avatar: '👩',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    _HistoryItem(
      action: 'Added',
      quantity: 3,
      unit: 'bottles',
      user: 'Mike Johnson',
      avatar: '👨‍🦰',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    _HistoryItem(
      action: 'Consumed',
      quantity: 1,
      unit: 'bottle',
      user: 'John Doe',
      avatar: '👨',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    ),
    _HistoryItem(
      action: 'Added',
      quantity: 6,
      unit: 'bottles',
      user: 'Emma Wilson',
      avatar: '👩‍🦰',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(colorScheme, textTheme),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalContentPadding,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: context.maxContentWidth,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildDrinkInfo(colorScheme, textTheme),
                      const SizedBox(height: 24),
                      _buildHistoryHeader(colorScheme, textTheme),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildHistoryList(colorScheme, textTheme),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme, TextTheme textTheme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
        title: FadeTransition(
          opacity: _controller,
          child: Text(
            widget.drinkName,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildDrinkInfo(ColorScheme colorScheme, TextTheme textTheme) {
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
            ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.lowStock
                      ? colorScheme.error.withValues(alpha: 0.3)
                      : colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: widget.lowStock ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primaryContainer,
                              colorScheme.secondaryContainer,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.local_drink_rounded,
                          size: 32,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.category,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${widget.quantity}',
                                  style: textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: widget.lowStock
                                        ? colorScheme.error
                                        : colorScheme.primary,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.unit,
                                  style: textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
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
                  if (widget.lowStock) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Low Stock',
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        Icon(Icons.history_rounded, color: colorScheme.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          'History',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${_history.length}',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(ColorScheme colorScheme, TextTheme textTheme) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalContentPadding,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.maxContentWidth),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 80)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistoryCard(
                    item: _history[index],
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    isLast: index == _history.length - 1,
                  ),
                ),
              ),
            ),
          );
        }, childCount: _history.length),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.colorScheme,
    required this.textTheme,
    required this.isLast,
  });

  final _HistoryItem item;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isAdded = item.action == 'Added';
    final actionColor = isAdded ? colorScheme.primary : colorScheme.tertiary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: actionColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                isAdded ? Icons.add_rounded : Icons.remove_rounded,
                color: actionColor,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.outlineVariant.withValues(alpha: 0.5),
                      colorScheme.outlineVariant.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(
                    alpha: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(item.avatar, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.user,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatTimestamp(item.timestamp),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: actionColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isAdded ? '+' : '-',
                                style: textTheme.labelLarge?.copyWith(
                                  color: actionColor,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${item.quantity}',
                                style: textTheme.labelLarge?.copyWith(
                                  color: actionColor,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.action} ${item.quantity} ${item.unit}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class _HistoryItem {
  const _HistoryItem({
    required this.action,
    required this.quantity,
    required this.unit,
    required this.user,
    required this.avatar,
    required this.timestamp,
  });

  final String action;
  final int quantity;
  final String unit;
  final String user;
  final String avatar;
  final DateTime timestamp;
}
