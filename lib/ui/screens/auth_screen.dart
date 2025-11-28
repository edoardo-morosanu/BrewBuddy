import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:brewbuddy/utils/responsive.dart';

import 'package:brewbuddy/services/auth_service.dart';
import 'package:brewbuddy/services/house_service.dart';
import 'package:brewbuddy/ui/screens/main_screen.dart';
import 'house_group_intro_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _isSignUp = false;
  bool _obscurePassword = true;
  late final AnimationController _fadeController;
  late final AnimationController _cardController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isSignUp = !_isSignUp);
    _formKey.currentState?.reset();
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim();

      try {
        if (_isSignUp) {
          await AuthService().signUp(
            email: email,
            password: password,
            name: name,
          );
        } else {
          await AuthService().signIn(
            email: email,
            password: password,
          );
        }

        if (mounted) {
          final user = AuthService().currentUser;
          if (user != null) {
            // Check if user is already in a house
            final house = await HouseService().getCurrentHouse();
            
            if (mounted) {
              if (house != null) {
                // User is in a house, go to Inventory (index 1)
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(initialIndex: 1),
                  ),
                );
              } else {
                // User is not in a house, go to Intro Screen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const HouseGroupIntroScreen(),
                  ),
                );
              }
            }
          } else {
            // If user is null after sign up/in, it likely means email confirmation is required
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please check your email to confirm your account.'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final isSmallScreen = size.height < 700;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final double heightScale = (size.height / 800).clamp(0.85, 1.2).toDouble();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Animated gradient background
              _buildAnimatedBackground(colorScheme),

              // Main content - Scrollable & responsive
              SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: constraints.maxWidth * 0.08,

                    right: constraints.maxWidth * 0.08,

                    top:
                        padding.top +
                        ((keyboardVisible ? 8 : (isSmallScreen ? 16 : 28)) *
                            heightScale),
                    bottom:
                        padding.bottom +
                        ((keyboardVisible ? 8 : (isSmallScreen ? 16 : 28)) *
                            heightScale),
                  ),

                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight -
                            padding.top -
                            padding.bottom -
                            ((keyboardVisible ? 8 : (isSmallScreen ? 16 : 28)) *
                                heightScale *
                                2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!keyboardVisible) ...[
                            SizedBox(
                              height: (isSmallScreen ? 24 : 40) * heightScale,
                            ),

                            _buildLogo(colorScheme, isSmallScreen),

                            SizedBox(
                              height: (isSmallScreen ? 16 : 24) * heightScale,
                            ),
                          ] else
                            const SizedBox(height: 8),

                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: Responsive.getMaxContentWidth(
                                  context,
                                ),
                              ),

                              child: _buildAuthCard(
                                context,
                                theme,

                                colorScheme,

                                isSmallScreen,

                                heightScale,
                              ),
                            ),
                          ),

                          if (!keyboardVisible)
                            SizedBox(
                              height: (isSmallScreen ? 24 : 40) * heightScale,
                            ),
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
      animation: _fadeController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.2),
                colorScheme.secondaryContainer.withValues(alpha: 0.15),
                colorScheme.tertiaryContainer.withValues(alpha: 0.1),
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
      opacity: _fadeController,
      child: Hero(
        tag: 'brew-buddy-logo',
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          shadowColor: colorScheme.primary.withValues(alpha: 0.3),
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Container(
            width: isSmallScreen ? 72 : 96,
            height: isSmallScreen ? 72 : 96,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
    );
  }

  Widget _buildAuthCard(
    BuildContext context,
    ThemeData theme,

    ColorScheme colorScheme,

    bool isSmallScreen,

    double heightScale,
  ) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeOutBack,
      ),
      child: FadeTransition(
        opacity: _cardController,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode toggle
                    _buildModeToggle(theme, colorScheme, isSmallScreen),

                    SizedBox(height: (isSmallScreen ? 16 : 24) * heightScale),

                    // Title
                    Text(
                      _isSignUp ? 'Create Account' : 'Welcome Back',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 20 : 24,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: isSmallScreen ? 4 : 6),

                    Text(
                      _isSignUp
                          ? 'Sign up to start managing your drinks'
                          : 'Sign in to continue',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: isSmallScreen ? 12 : 13,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: (isSmallScreen ? 16 : 24) * heightScale),

                    // Form fields
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Column(
                        children: [
                          if (_isSignUp) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'Enter your name',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (_isSignUp && (value?.isEmpty ?? true)) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: isSmallScreen ? 10 : 14),
                          ],
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'your@email.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value!)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isSmallScreen ? 10 : 14),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleSubmit(),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter your password';
                              }
                              if (_isSignUp && value!.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    if (!_isSignUp) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password reset - Coming soon!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),

                          child: Text(
                            'Forgot password?',

                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: isSmallScreen ? 16 : 20),

                    FilledButton(
                      onPressed: _handleSubmit,

                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(context.buttonHeight),

                        backgroundColor: colorScheme.primary,

                        foregroundColor: colorScheme.onPrimary,

                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),

                      child: Text(
                        _isSignUp ? 'Sign Up' : 'Sign In',

                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,

                          fontSize: context.responsiveFontSize(
                            base: 16,
                            tablet: 17,
                            desktop: 18,
                          ),
                          color: colorScheme.onPrimary,
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
    );
  }

  Widget _buildModeToggle(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isSmallScreen,
  ) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),

      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Sign In',
              isActive: !_isSignUp,

              onTap: _isSignUp ? _toggleMode : null,

              colorScheme: colorScheme,

              theme: theme,

              isSmallScreen: isSmallScreen,
            ),
          ),

          Expanded(
            child: _ModeButton(
              label: 'Sign Up',

              isActive: _isSignUp,

              onTap: !_isSignUp ? _toggleMode : null,

              colorScheme: colorScheme,

              theme: theme,

              isSmallScreen: isSmallScreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.colorScheme,
    required this.theme,
    required this.isSmallScreen,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,

          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,

            color: isActive
                ? colorScheme.onPrimary
                : colorScheme.onSurface.withValues(alpha: 0.6),
          ),

          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
