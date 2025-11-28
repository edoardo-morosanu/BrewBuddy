import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:brewbuddy/utils/responsive.dart';

import 'auth_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthScreen(),
        transitionDuration: const Duration(milliseconds: 800),
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final padding = MediaQuery.of(context).padding;
    final isVerySmallScreen = size.height < 600;
    final double heightScale = (size.height / 800).clamp(0.85, 1.2).toDouble();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Animated gradient background
              _buildAnimatedBackground(colorScheme),

              // Main content - scrollable and responsive
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: context.maxContentWidth,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        context.responsiveValue(
                          mobile: constraints.maxWidth * 0.08,
                          tablet: 32.0,
                          desktop: 48.0,
                        ),
                        context.isSmallScreen ? 16 : 24,
                        context.responsiveValue(
                          mobile: constraints.maxWidth * 0.08,
                          tablet: 32.0,
                          desktop: 48.0,
                        ),
                        context.isSmallScreen ? 16 : 24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          _buildLogo(colorScheme, context.isSmallScreen),

                          SizedBox(height: context.responsiveSpacing(base: 24)),

                          // Title
                          _buildTitle(theme, context.isSmallScreen),

                          SizedBox(height: context.responsiveSpacing(base: 12)),

                          // Subtitle
                          _buildSubtitle(
                            theme,
                            colorScheme,
                            context.isSmallScreen,
                          ),

                          SizedBox(height: context.responsiveSpacing(base: 32)),

                          // Features
                          _buildFeatures(
                            theme,
                            colorScheme,
                            context.isSmallScreen,
                          ),

                          SizedBox(height: context.responsiveSpacing(base: 32)),

                          // Get started button
                          _buildGetStartedButton(
                            theme,
                            colorScheme,
                            constraints.maxWidth,
                            context.isSmallScreen,
                          ),

                          SizedBox(height: context.responsiveSpacing(base: 24)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedBackground(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.15),
                colorScheme.secondaryContainer.withValues(alpha: 0.1),
                colorScheme.surface,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -100,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.08),
                        colorScheme.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.tertiary.withValues(alpha: 0.08),
                        colorScheme.tertiary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogo(ColorScheme colorScheme, bool isSmallScreen) {
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        child: Hero(
          tag: 'brew-buddy-logo',
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(24),
            shadowColor: colorScheme.primary.withValues(alpha: 0.3),
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Container(
              width:
                  (isSmallScreen ? 96.0 : 120.0) *
                  MediaQuery.of(context).textScaleFactor.clamp(0.9, 1.2),
              height:
                  (isSmallScreen ? 96.0 : 120.0) *
                  MediaQuery.of(context).textScaleFactor.clamp(0.9, 1.2),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  colorScheme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  BlendMode.srcIn,
                ),
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, bool isSmallScreen) {
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
            ),
        child: Text(
          'Brew Buddy',

          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w900,

            letterSpacing: -1,
            height: 1.15,
            color: theme.colorScheme.onSurface,
          ),

          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSubtitle(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isSmallScreen,
  ) {
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
            ),
        child: Text(
          'Somewhere in the world it\'s already 5pm!',

          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),

            height: 1.3,
          ),

          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ),
    );
  }

  Widget _buildFeatures(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isSmallScreen,
  ) {
    final features = [
      {'icon': Icons.qr_code_scanner_rounded, 'text': 'Quick Scanning'},
      {'icon': Icons.group_rounded, 'text': 'Shared Groups'},
      {'icon': Icons.notifications_active_rounded, 'text': 'Smart Alerts'},
    ];

    return FadeTransition(
      opacity: _controller,

      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: features
            .map(
              (feature) => ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      (isSmallScreen ? 110.0 : 140.0) *
                      MediaQuery.of(context).textScaleFactor.clamp(0.9, 1.2),

                  minWidth:
                      (isSmallScreen ? 100.0 : 120.0) *
                      MediaQuery.of(context).textScaleFactor.clamp(0.9, 1.2),
                ),

                child: _FeatureCard(
                  icon: feature['icon'] as IconData,

                  text: feature['text'] as String,

                  colorScheme: colorScheme,

                  theme: theme,

                  isSmallScreen: isSmallScreen,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildGetStartedButton(
    ThemeData theme,
    ColorScheme colorScheme,
    double screenWidth,
    bool isSmallScreen,
  ) {
    final maxWidth = context.responsiveValue(
      mobile: 420.0,
      tablet: 520.0,
      desktop: 600.0,
    );
    final buttonHeight = context.buttonHeight;
    final textSize = context.responsiveFontSize(
      base: 16,
      tablet: 17,
      desktop: 18,
    );
    final iconSize = context.responsiveIconSize(
      base: 20,
      tablet: 22,
      desktop: 24,
    );

    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            context.responsiveBorderRadius(base: 16),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: _navigateToAuth,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            minimumSize: Size.fromHeight(buttonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(base: 16),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Get Started',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: textSize,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: colorScheme.onPrimary,
                size: iconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.text,
    required this.colorScheme,
    required this.theme,
    required this.isSmallScreen,
  });

  final IconData icon;
  final String text;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),

                child: Icon(
                  icon,

                  color: colorScheme.primary,

                  size:
                      (isSmallScreen ? 18.0 : 22.0) *
                      MediaQuery.of(context).textScaleFactor.clamp(0.9, 1.2),
                ),
              ),
              SizedBox(height: isSmallScreen ? 4 : 6),
              Text(
                text,

                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,

                  fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
                  color: colorScheme.onSurface,
                ),

                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
