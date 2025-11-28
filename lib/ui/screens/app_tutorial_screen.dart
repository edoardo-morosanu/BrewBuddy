import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'main_screen.dart';

class AppTutorialScreen extends StatefulWidget {
  const AppTutorialScreen({super.key});

  @override
  State<AppTutorialScreen> createState() => _AppTutorialScreenState();
}

class _AppTutorialScreenState extends State<AppTutorialScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _backgroundController;
  late final AnimationController _progressController;
  int _currentPage = 0;

  final List<_TutorialPage> _pages = const [
    _TutorialPage(
      icon: Icons.inventory_2_outlined,
      title: 'Drink Inventory',
      description:
          'View all your household drinks in one place. See quantities, who added what, and what needs restocking.',
      features: [
        'Real-time drink list',
        'Quantity tracking',
        'Smart sorting options',
      ],
      accentColor: Color(0xFF6750A4),
    ),
    _TutorialPage(
      icon: Icons.qr_code_scanner_rounded,
      title: 'Quick Scan',
      description:
          'Simply scan a barcode to add or remove drinks. Fast, easy, and accurate.',
      features: [
        'Instant barcode scanning',
        'Add new drinks',
        'Update quantities',
      ],
      accentColor: Color(0xFF7D5260),
    ),
    _TutorialPage(
      icon: Icons.home_work_outlined,
      title: 'House Management',
      description:
          'Manage your household group, invite members, and view house statistics all in one place.',
      features: ['Member management', 'House settings', 'Group statistics'],
      accentColor: Color(0xFF006A6A),
    ),
    _TutorialPage(
      icon: Icons.person_outline_rounded,
      title: 'Personal Dashboard',
      description:
          'Track your personal contributions, drinking habits, and see your impact on the household.',
      features: ['Drinks consumed', 'Drinks added', 'Personal statistics'],
      accentColor: Color(0xFF984061),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pageController.addListener(_handlePageChange);
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageChange);
    _pageController.dispose();
    _backgroundController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _handlePageChange() {
    final page = _pageController.page ?? 0;
    final newPage = page.round();
    if (newPage != _currentPage && mounted) {
      setState(() => _currentPage = newPage);
      _progressController.forward(from: 0);
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishTutorial();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _skipTutorial() {
    _finishTutorial();
  }

  bool _isNavigating = false;

  void _finishTutorial() {
    if (_isNavigating) return;
    _isNavigating = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          _AnimatedBackground(
            controller: _backgroundController,
            colorScheme: colorScheme,
            currentPage: _currentPage,
            pageCount: _pages.length,
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(colorScheme),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _TutorialPageView(
                        page: _pages[index],
                        index: index,
                        currentPage: _currentPage,
                      );
                    },
                  ),
                ),
                _buildBottomControls(colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ColorScheme colorScheme) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = width >= 900
        ? 40.0
        : width >= 600
        ? 32.0
        : 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 16),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(
            'Getting Started',

            style: TextStyle(
              fontSize: 16,

              fontWeight: FontWeight.w600,

              color: colorScheme.onSurface,
            ),
          ),

          TextButton(
            onPressed: _skipTutorial,

            child: const Text(
              'Skip',

              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(ColorScheme colorScheme) {
    final isLastPage = _currentPage == _pages.length - 1;

    final width = MediaQuery.of(context).size.width;

    final horizontal = width >= 900
        ? 40.0
        : width >= 600
        ? 32.0
        : 24.0;
    final vertical = 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          _buildPageIndicator(colorScheme),

          const SizedBox(height: 24),

          Row(
            children: [
              if (_currentPage > 0)
                IconButton.outlined(
                  onPressed: _previousPage,

                  icon: const Icon(Icons.arrow_back_rounded),

                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                  ),
                )
              else
                const SizedBox(width: 48),

              const SizedBox(width: 16),

              Expanded(
                child: FilledButton(
                  onPressed: _nextPage,

                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),

                    backgroundColor: _pages[_currentPage].accentColor,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  child: Text(
                    isLastPage ? 'Get Started' : 'Next',

                    style: const TextStyle(
                      fontSize: 16,

                      fontWeight: FontWeight.w600,

                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? _pages[_currentPage].accentColor
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _TutorialPage {
  const _TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final Color accentColor;
}

class _TutorialPageView extends StatelessWidget {
  const _TutorialPageView({
    required this.page,
    required this.index,
    required this.currentPage,
  });

  final _TutorialPage page;
  final int index;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    final textTheme = theme.textTheme;

    final isActive = index == currentPage;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),

      opacity: isActive ? 1.0 : 0.4,

      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 600;

          final maxContentWidth = constraints.maxWidth > 600
              ? 600.0
              : constraints.maxWidth;
          final horizontal = constraints.maxWidth >= 900
              ? 40.0
              : constraints.maxWidth >= 600
              ? 32.0
              : 24.0;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    _buildIconCard(colorScheme, isCompact),

                    SizedBox(height: isCompact ? 28 : 40),

                    Text(
                      page.title,

                      style:
                          (isCompact
                                  ? textTheme.headlineSmall
                                  : textTheme.headlineMedium)
                              ?.copyWith(
                                fontWeight: FontWeight.w800,

                                color: colorScheme.onSurface,

                                letterSpacing: -0.5,
                              ),

                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: isCompact ? 12 : 16),

                    Text(
                      page.description,

                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,

                        height: 1.5,
                      ),

                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: isCompact ? 24 : 32),

                    _buildFeaturesList(colorScheme, textTheme, isCompact),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconCard(ColorScheme colorScheme, bool isCompact) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: isCompact ? 120 : 140,
            height: isCompact ? 120 : 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  page.accentColor.withValues(alpha: 0.3),
                  page.accentColor.withValues(alpha: 0.15),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: page.accentColor.withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: isCompact ? 56 : 64,
              color: page.accentColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturesList(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isCompact,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 18 : 24),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: page.accentColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: page.features.asMap().entries.map((entry) {
              final index = entry.key;
              final feature = entry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 100)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(20 * (1 - value), 0),
                    child: Opacity(
                      opacity: value,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isCompact ? 8 : 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: page.accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: isCompact ? 16 : 18,
                                color: page.accentColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style:
                                    (isCompact
                                            ? textTheme.bodyMedium
                                            : textTheme.bodyLarge)
                                        ?.copyWith(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({
    required this.controller,
    required this.colorScheme,
    required this.currentPage,
    required this.pageCount,
  });

  final AnimationController controller;
  final ColorScheme colorScheme;
  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = Curves.easeInOutSine.transform(controller.value);
        final t2 = Curves.easeInOutSine.transform(
          ((controller.value + 0.5) % 1.0),
        );

        // Different colors based on current page
        final pageProgress = currentPage / (pageCount - 1);
        final baseColor1 = Color.lerp(
          colorScheme.primaryContainer,
          colorScheme.tertiaryContainer,
          pageProgress,
        )!;
        final baseColor2 = Color.lerp(
          colorScheme.secondaryContainer,
          colorScheme.primaryContainer,
          pageProgress,
        )!;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  baseColor1.withValues(alpha: 0.3),
                  baseColor2.withValues(alpha: 0.4),
                  t,
                )!,
                colorScheme.surface,
                Color.lerp(
                  baseColor2.withValues(alpha: 0.25),
                  baseColor1.withValues(alpha: 0.3),
                  t,
                )!,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -100 + (80 * math.sin(t * math.pi)),
                left: -80 + (60 * math.cos(t * math.pi)),
                child: _GlowingOrb(
                  color: baseColor1.withValues(alpha: 0.15),
                  size: 300 + (50 * math.sin(t * math.pi * 2)),
                ),
              ),
              Positioned(
                top: 200 + (100 * math.sin(t2 * math.pi)),
                right: -120 + (80 * math.cos(t2 * math.pi)),
                child: _GlowingOrb(
                  color: colorScheme.tertiary.withValues(alpha: 0.12),
                  size: 250 + (40 * math.cos(t2 * math.pi * 2)),
                ),
              ),
              Positioned(
                bottom: -80 + (60 * math.cos(t * math.pi)),
                left: 100 + (70 * math.sin(t * math.pi)),
                child: _GlowingOrb(
                  color: baseColor2.withValues(alpha: 0.1),
                  size: 280 + (45 * math.sin(t * math.pi * 1.5)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowingOrb extends StatelessWidget {
  const _GlowingOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: color.a),
            color.withValues(alpha: color.a * 0.6),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
