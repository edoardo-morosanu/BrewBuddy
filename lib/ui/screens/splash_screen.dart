import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _timeSwapController;
  late final AnimationController _fadeOutController;
  late final AnimationController _bubbleController;

  @override
  void initState() {
    super.initState();

    // Background animation
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Text slide animation (initial entry)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Time swap animation (7am -> 5pm)
    _timeSwapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Fade out animation for transition
    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Bubble animation - continuous, very slow for subtle morphing
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // 1. Animate logo in
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) _logoController.forward();

    // 2. Show first text "7am"
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) _textController.forward();

    // 3. Wait, then slide up 7am and bring in 5pm
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      _timeSwapController.forward();
    }

    // 4. Wait a bit, then fade out and navigate
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      await _fadeOutController.forward();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                widget.nextScreen,
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _timeSwapController.dispose();
    _fadeOutController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: _fadeOutController, curve: Curves.easeInOut),
        ),
        child: Stack(
          children: [
            // Animated gradient background
            _buildAnimatedBackground(colorScheme, size),

            // Morphing bubbles
            _buildMorphingBubbles(colorScheme, size),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with scale animation
                  _buildLogo(colorScheme),

                  const SizedBox(height: 60),

                  // Animated text with slide transitions
                  _buildAnimatedText(theme, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(ColorScheme colorScheme, Size size) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.15),
                colorScheme.secondary.withValues(alpha: 0.1),
                colorScheme.tertiary.withValues(alpha: 0.15),
                colorScheme.primary.withValues(alpha: 0.2),
              ],
              stops: [
                0.0,
                0.3 + (_backgroundController.value * 0.2),
                0.6 + (_backgroundController.value * 0.2),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMorphingBubbles(ColorScheme colorScheme, Size size) {
    return AnimatedBuilder(
      animation: _bubbleController,
      builder: (context, child) {
        return CustomPaint(
          size: size,
          painter: MorphingBubblePainter(
            animationValue: _bubbleController.value,
            primaryColor: colorScheme.primary,
            secondaryColor: colorScheme.secondary,
            tertiaryColor: colorScheme.tertiary,
          ),
        );
      },
    );
  }

  Widget _buildLogo(ColorScheme colorScheme) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
      child: FadeTransition(
        opacity: _logoController,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.3),
                colorScheme.secondary.withValues(alpha: 0.3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: colorScheme.secondary.withValues(alpha: 0.3),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surface.withValues(alpha: 0.3),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: 70,
                    height: 70,
                    colorFilter: ColorFilter.mode(
                      colorScheme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedText(ThemeData theme, ColorScheme colorScheme) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _textController,
              curve: Curves.easeOutCubic,
            ),
          ),
      child: FadeTransition(
        opacity: _textController,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.1),
                colorScheme.secondary.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Somewhere in the world",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "it's already ",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      fontSize: 24, // Match headline size roughly
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    width: 80,
                    child: Stack(
                      children: [
                        // 7am - slides out up
                        SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: Offset.zero,
                                end: const Offset(0, -1.5),
                              ).animate(
                                CurvedAnimation(
                                  parent: _timeSwapController,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 1.0, end: 0.0)
                                .animate(
                                  CurvedAnimation(
                                    parent: _timeSwapController,
                                    curve: const Interval(0.0, 0.5),
                                  ),
                                ),
                            child: _buildGradientText(
                              "7am!",
                              colorScheme,
                              theme,
                            ),
                          ),
                        ),
                        // 5pm - slides in from down
                        SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, 1.5),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _timeSwapController,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0.0, end: 1.0)
                                .animate(
                                  CurvedAnimation(
                                    parent: _timeSwapController,
                                    curve: const Interval(0.5, 1.0),
                                  ),
                                ),
                            child: _buildGradientText(
                              "5pm!",
                              colorScheme,
                              theme,
                            ),
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
    );
  }

  Widget _buildGradientText(
    String text,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [colorScheme.primary, colorScheme.secondary],
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class MorphingBubblePainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final math.Random _random = math.Random(42); // Fixed seed for consistency

  MorphingBubblePainter({
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create multiple bubbles with different properties
    final bubbles = _generateBubbles(size);

    for (final bubble in bubbles) {
      _drawMorphingBubble(canvas, size, bubble);
    }
  }

  List<BubbleData> _generateBubbles(Size size) {
    // Fewer bubbles (5), more varied sizes
    final positions = [
      [0.15, 0.20], // Top-left
      [0.85, 0.15], // Top-right
      [0.50, 0.50], // Center
      [0.20, 0.80], // Bottom-left
      [0.80, 0.75], // Bottom-right
    ];

    // Varied sizes: small to very large
    final sizes = [40.0, 120.0, 100.0, 50.0, 90.0];
    final frequencies = [0.8, 0.5, 0.3, 0.9, 0.6];
    final phases = [0.0, 2.0, 4.0, 1.0, 3.0];

    return List.generate(5, (index) {
      return BubbleData(
        index: index,
        baseX: size.width * positions[index][0],
        baseY: size.height * positions[index][1],
        baseRadius: sizes[index],
        morphFrequency: frequencies[index],
        colorIndex: 0,
        phase: phases[index],
      );
    });
  }

  void _drawMorphingBubble(Canvas canvas, Size size, BubbleData bubble) {
    // Static position - no movement
    final centerX = bubble.baseX;
    final centerY = bubble.baseY;

    // Constant opacity
    const opacity = 0.7;

    // Create morphing bubble path
    final path = _createMorphingBubblePath(
      centerX,
      centerY,
      bubble.baseRadius,
      animationValue + bubble.phase,
      bubble.morphFrequency,
    );

    // Draw bubble with gradient and shine
    _drawBubbleWithEffects(canvas, path, centerX, centerY, bubble, opacity);
  }

  Path _createMorphingBubblePath(
    double centerX,
    double centerY,
    double radius,
    double progress,
    double morphFrequency,
  ) {
    final path = Path();
    const segments = 64; // Smoother

    for (var i = 0; i <= segments; i++) {
      final angle = (i / segments) * math.pi * 2;

      // Nicer morphs: more complex wave combination
      final morph1 =
          math.sin(angle * 2 + progress * math.pi * 2 * morphFrequency) * 0.08;
      final morph2 =
          math.sin(angle * 3 - progress * math.pi * 2 * morphFrequency * 0.7) *
          0.05;
      final morph3 =
          math.sin(angle * 5 + progress * math.pi * 2 * morphFrequency * 0.4) *
          0.03;
      final morph4 =
          math.cos(angle * 2 + progress * math.pi * 2 * morphFrequency * 0.2) *
          0.03;

      final morphedRadius = radius * (1.0 + morph1 + morph2 + morph3 + morph4);

      final x = centerX + math.cos(angle) * morphedRadius;
      final y = centerY + math.sin(angle) * morphedRadius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }

  void _drawBubbleWithEffects(
    Canvas canvas,
    Path path,
    double centerX,
    double centerY,
    BubbleData bubble,
    double opacity,
  ) {
    // Use beer-like amber/orange color that blends with theme
    // Blue bubbles as requested
    final bubbleColor = Colors.lightBlueAccent;

    // Main bubble fill with radial gradient
    final rect = Rect.fromCircle(
      center: Offset(centerX, centerY),
      radius: bubble.baseRadius,
    );

    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 1.2,
      colors: [
        bubbleColor.withValues(alpha: 0.4 * opacity),
        bubbleColor.withValues(alpha: 0.2 * opacity),
        bubbleColor.withValues(alpha: 0.05 * opacity),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final bubblePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, bubblePaint);

    // Outer rim/edge - very soft
    final rimPaint = Paint()
      ..color = bubbleColor.withValues(alpha: 0.3 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, rimPaint);

    // Highlight/shine effect
    final shinePath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(
            centerX - bubble.baseRadius * 0.25,
            centerY - bubble.baseRadius * 0.25,
          ),
          radius: bubble.baseRadius * 0.3,
        ),
      );

    final shinePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.4 * opacity),
              Colors.white.withValues(alpha: 0.08 * opacity),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                centerX - bubble.baseRadius * 0.25,
                centerY - bubble.baseRadius * 0.25,
              ),
              radius: bubble.baseRadius * 0.3,
            ),
          )
      ..style = PaintingStyle.fill;

    canvas.drawPath(shinePath, shinePaint);

    // Secondary smaller highlight
    final smallShinePath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(
            centerX + bubble.baseRadius * 0.3,
            centerY + bubble.baseRadius * 0.15,
          ),
          radius: bubble.baseRadius * 0.15,
        ),
      );

    final smallShinePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.3 * opacity),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                centerX + bubble.baseRadius * 0.3,
                centerY + bubble.baseRadius * 0.15,
              ),
              radius: bubble.baseRadius * 0.15,
            ),
          )
      ..style = PaintingStyle.fill;

    canvas.drawPath(smallShinePath, smallShinePaint);
  }

  @override
  bool shouldRepaint(MorphingBubblePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class BubbleData {
  final int index;
  final double baseX;
  final double baseY;
  final double baseRadius;
  final double morphFrequency;
  final int colorIndex;
  final double phase;

  BubbleData({
    required this.index,
    required this.baseX,
    required this.baseY,
    required this.baseRadius,
    required this.morphFrequency,
    required this.colorIndex,
    required this.phase,
  });
}
