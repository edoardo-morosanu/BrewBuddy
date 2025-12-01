import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:brewbuddy/utils/responsive.dart';

import '../../models/drink_item.dart';

class DrinkDetailScreen extends StatefulWidget {
  const DrinkDetailScreen({super.key, required this.drink});

  final DrinkItem drink;

  @override
  State<DrinkDetailScreen> createState() => _DrinkDetailScreenState();
}

class _DrinkDetailScreenState extends State<DrinkDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
    final hasImage =
        widget.drink.imageUrl != null && widget.drink.imageUrl!.isNotEmpty;

    return SliverAppBar(
      expandedHeight: hasImage ? 300 : 120,
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
            widget.drink.name,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: hasImage ? Colors.white : colorScheme.onSurface,
              shadows: hasImage
                  ? [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        background: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.drink.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: colorScheme.surfaceContainerHigh);
                    },
                  ),
                  // Gradient overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              )
            : null,
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
                  color: widget.drink.lowStock
                      ? colorScheme.error.withValues(alpha: 0.3)
                      : colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: widget.drink.lowStock ? 2 : 1,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
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
                          size: 28,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.drink.category.toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Added by ${widget.drink.addedBy}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.drink.quantity}',
                        style: textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: widget.drink.lowStock
                              ? colorScheme.error
                              : colorScheme.primary,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          widget.drink.unit,
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (widget.drink.lowStock)
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
                  ),
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
            '${widget.drink.history.length}',
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
                    item: widget.drink.history[index],
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    isLast: index == widget.drink.history.length - 1,
                  ),
                ),
              ),
            ),
          );
        }, childCount: widget.drink.history.length),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    super.key,
    required this.item,
    required this.isLast,
    required this.colorScheme,
    required this.textTheme,
  });

  final HistoryEntry item;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getActionColor(),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _getActionColor().withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getActionText(),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getActionColor(),
                      ),
                    ),
                    Text(
                      _formatDate(item.date),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.user} • ${item.amount} units',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                if (item.note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.note!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getActionColor() {
    switch (item.action) {
      case HistoryAction.added:
      case HistoryAction.restocked:
        return colorScheme.primary;
      case HistoryAction.removed:
        return colorScheme.error;
      case HistoryAction.adjusted:
        return colorScheme.tertiary;
    }
  }

  String _getActionText() {
    switch (item.action) {
      case HistoryAction.added:
        return 'Added Stock';
      case HistoryAction.restocked:
        return 'Restocked';
      case HistoryAction.removed:
        return 'Consumed';
      case HistoryAction.adjusted:
        return 'Adjusted';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
