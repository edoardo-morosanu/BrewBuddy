import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:brewbuddy/services/house_service.dart';
import 'app_tutorial_screen.dart';

class HouseGroupIntroScreen extends StatefulWidget {
  const HouseGroupIntroScreen({super.key});

  @override
  State<HouseGroupIntroScreen> createState() => _HouseGroupIntroScreenState();
}

class _HouseGroupIntroScreenState extends State<HouseGroupIntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _contentController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Start content animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _contentController.forward();
      }
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showJoinGroupDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          _JoinGroupDialog(onJoinSuccess: _navigateToTutorial),
    );
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          _CreateGroupDialog(onCreateSuccess: _navigateToTutorial),
    );
  }

  void _handleCreateGroup() {
    _showCreateGroupDialog();
  }

  void _navigateToTutorial() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AppTutorialScreen(),
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
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Stack(
        children: [
          _AnimatedBackground(
            controller: _backgroundController,
            colorScheme: colorScheme,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 700;

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth > 600 ? 48 : 24,
                    vertical: isCompact ? 16 : 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeader(colorScheme, textTheme, isCompact),
                      SizedBox(height: isCompact ? 16 : 24),
                      _buildContent(
                        colorScheme,
                        textTheme,
                        constraints.maxWidth,
                        isCompact,
                      ),
                      SizedBox(height: isCompact ? 16 : 24),
                      _buildActions(colorScheme, textTheme, isCompact),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isCompact,
  ) {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        final slideProgress = Curves.easeOutCubic.transform(
          math.min(_contentController.value * 1.5, 1.0),
        );
        final fadeProgress = Curves.easeOut.transform(
          math.min(_contentController.value * 2.0, 1.0),
        );

        return Transform.translate(
          offset: Offset(0, 30 * (1 - slideProgress)),
          child: Opacity(
            opacity: fadeProgress,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 14 : 18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.home_outlined,
                    size: isCompact ? 40 : 56,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(height: isCompact ? 12 : 20),
                Text(
                  'Your House Group',
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
                SizedBox(height: isCompact ? 8 : 12),
                Text(
                  'Share drinks, track inventory, and stay\norganized with your household',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    ColorScheme colorScheme,
    TextTheme textTheme,
    double maxWidth,
    bool isCompact,
  ) {
    final cardWidth = math.min(maxWidth > 600 ? 560.0 : maxWidth, maxWidth);

    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        final slideProgress = Curves.easeOutCubic.transform(
          math.max(0, math.min((_contentController.value - 0.2) * 1.5, 1.0)),
        );
        final fadeProgress = Curves.easeOut.transform(
          math.max(0, math.min((_contentController.value - 0.2) * 2.0, 1.0)),
        );

        return Transform.translate(
          offset: Offset(0, 40 * (1 - slideProgress)),
          child: Opacity(
            opacity: fadeProgress,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Column(
                  children: [
                    _FeatureCard(
                      icon: Icons.groups_outlined,
                      title: 'Collaborate Together',
                      description:
                          'Invite household members and manage drinks as a team',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      isCompact: isCompact,
                    ),
                    SizedBox(height: isCompact ? 12 : 16),
                    _FeatureCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Shared Inventory',
                      description:
                          'Keep track of what\'s available and what needs restocking',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      isCompact: isCompact,
                    ),
                    SizedBox(height: isCompact ? 12 : 16),
                    _FeatureCard(
                      icon: Icons.notifications_active_outlined,
                      title: 'Smart Reminders',
                      description: 'Get notified when supplies are running low',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      isCompact: isCompact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isCompact,
  ) {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        final slideProgress = Curves.easeOutCubic.transform(
          math.max(0, math.min((_contentController.value - 0.4) * 1.5, 1.0)),
        );
        final fadeProgress = Curves.easeOut.transform(
          math.max(0, math.min((_contentController.value - 0.4) * 2.0, 1.0)),
        );

        return Transform.translate(
          offset: Offset(0, 50 * (1 - slideProgress)),
          child: Opacity(
            opacity: fadeProgress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: _handleCreateGroup,
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(
                    'Create New Group',
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 14 : 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
                SizedBox(height: isCompact ? 12 : 14),
                OutlinedButton.icon(
                  onPressed: _showJoinGroupDialog,
                  icon: const Icon(Icons.login_outlined),
                  label: Text(
                    'Join Existing Group',
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 14 : 16,
                      horizontal: 24,
                    ),
                    side: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.colorScheme,
    required this.textTheme,
    required this.isCompact,
  });

  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 10 : 12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: isCompact ? 22 : 24,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(width: isCompact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          (isCompact
                                  ? textTheme.titleSmall
                                  : textTheme.titleMedium)
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                    ),
                    SizedBox(height: isCompact ? 2 : 4),
                    Text(
                      description,
                      style:
                          (isCompact
                                  ? textTheme.bodySmall
                                  : textTheme.bodyMedium)
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.3,
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

class _JoinGroupDialog extends StatefulWidget {
  const _JoinGroupDialog({required this.onJoinSuccess});

  final VoidCallback onJoinSuccess;

  @override
  State<_JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends State<_JoinGroupDialog>
    with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _scaleController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleJoin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await HouseService().joinHouse(inviteCode: _codeController.text.trim());

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pop();
        widget.onJoinSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutCubic,
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.vpn_key_outlined,
                              size: 24,
                              color: colorScheme.tertiary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Join Group',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Enter the 6-digit code shared by your group admin',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _codeController,
                        enabled: !_isLoading,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          hintText: '000ABC',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: colorScheme.tertiary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: colorScheme.error,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 16,
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                          UpperCaseTextFormatter(),
                        ],
                        maxLength: 6,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a code';
                          }
                          if (value.length != 6) {
                            return 'Code must be 6 digits';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleJoin(),
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _isLoading ? null : _handleJoin,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.tertiary,
                          foregroundColor: colorScheme.onTertiary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    colorScheme.onTertiary,
                                  ),
                                ),
                              )
                            : const Text(
                                'Join Group',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () {
                                // TODO: Open help/info
                              },
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: const Text(
                          'Don\'t have a code?',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
  });

  final AnimationController controller;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = Curves.easeInOutSine.transform(controller.value);
        final t2 = Curves.easeInOutSine.transform(
          ((controller.value + 0.5) % 1.0),
        );

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  colorScheme.primaryContainer.withValues(alpha: 0.3),
                  colorScheme.secondaryContainer.withValues(alpha: 0.4),
                  t,
                )!,
                colorScheme.surface,
                Color.lerp(
                  colorScheme.tertiaryContainer.withValues(alpha: 0.25),
                  colorScheme.primaryContainer.withValues(alpha: 0.3),
                  t,
                )!,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -120 + (100 * math.sin(t * math.pi)),
                left: -100 + (80 * math.cos(t * math.pi)),
                child: _GlowingOrb(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  size: 350 + (60 * math.sin(t * math.pi * 2)),
                ),
              ),
              Positioned(
                top: 150 + (120 * math.sin(t2 * math.pi)),
                right: -140 + (90 * math.cos(t2 * math.pi)),
                child: _GlowingOrb(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  size: 300 + (50 * math.cos(t2 * math.pi * 2)),
                ),
              ),
              Positioned(
                bottom: -100 + (80 * math.cos(t * math.pi)),
                left: 80 + (100 * math.sin(t * math.pi)),
                child: _GlowingOrb(
                  color: colorScheme.tertiary.withValues(alpha: 0.11),
                  size: 320 + (55 * math.sin(t * math.pi * 1.5)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
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

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog({required this.onCreateSuccess});

  final VoidCallback onCreateSuccess;

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _scaleController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await HouseService().createHouse(name: _nameController.text.trim());

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pop();
        widget.onCreateSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutCubic,
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.add_home_outlined,
                              size: 24,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Create Group',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Give your house group a name',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isLoading,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'e.g. The Brew Crew',
                          labelText: 'House Name',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleCreate(),
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _isLoading ? null : _handleCreate,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : const Text(
                                'Create Group',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
