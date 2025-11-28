import 'dart:ui';

import 'package:flutter/material.dart';

class ModernBottomNavBar extends StatefulWidget {
  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<ModernBottomNavBar> createState() => _ModernBottomNavBarState();
}

class _ModernBottomNavBarState extends State<ModernBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ModernBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const itemCount = 3;
                    final availableWidth = constraints.maxWidth;
                    final itemWidth = availableWidth / itemCount;
                    const indicatorSize = 64.0;
                    final indicatorLeft =
                        (itemWidth * widget.currentIndex) +
                        (itemWidth / 2) -
                        (indicatorSize / 2);

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated indicator
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            final curve = Curves.easeOutCubic.transform(
                              _controller.value,
                            );
                            return AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),

                              curve: Curves.easeOutCubic,

                              left: indicatorLeft,
                              child: Transform.scale(
                                scale: 0.8 + (0.2 * curve),

                                child: Container(
                                  width: indicatorSize,
                                  height: indicatorSize,
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        colorScheme.primary.withValues(
                                          alpha: 0.2,
                                        ),

                                        colorScheme.primary.withValues(
                                          alpha: 0.0,
                                        ),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Navigation items
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,

                          children: [
                            _NavItem(
                              icon: Icons.home_work_outlined,

                              activeIcon: Icons.home_work_rounded,

                              label: 'Group',

                              isActive: widget.currentIndex == 0,

                              onTap: () => widget.onTap(0),

                              colorScheme: colorScheme,
                            ),
                            _NavItem(
                              icon: Icons.inventory_2_outlined,

                              activeIcon: Icons.inventory_2_rounded,

                              label: 'Inventory',

                              isActive: widget.currentIndex == 1,

                              onTap: () => widget.onTap(1),

                              colorScheme: colorScheme,

                              isCenter: true,
                            ),
                            _NavItem(
                              icon: Icons.person_outline_rounded,

                              activeIcon: Icons.person_rounded,

                              label: 'Profile',

                              isActive: widget.currentIndex == 2,

                              onTap: () => widget.onTap(2),

                              colorScheme: colorScheme,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Indicator position is computed responsively using LayoutBuilder; helper removed.
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.colorScheme,
    this.isCenter = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isCenter;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.reverse();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.forward();
    widget.onTap();
  }

  void _handleTapCancel() {
    _scaleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleController,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isActive ? 20 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.colorScheme.primaryContainer.withValues(alpha: 0.6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with animated switcher
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  widget.isActive ? widget.activeIcon : widget.icon,
                  key: ValueKey(widget.isActive),
                  size: widget.isCenter && widget.isActive ? 30 : 26,
                  color: widget.isActive
                      ? widget.colorScheme.primary
                      : widget.colorScheme.onSurfaceVariant,
                ),
              ),

              // Animated label
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: widget.isActive
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.colorScheme.primary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
