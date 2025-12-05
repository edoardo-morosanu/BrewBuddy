import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brewbuddy/services/auth_service.dart';
import 'package:brewbuddy/ui/screens/welcome_screen.dart';
import 'package:brewbuddy/utils/responsive.dart';
import 'package:brewbuddy/utils/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(colorScheme, textTheme),
          _buildSettingsList(colorScheme, textTheme, theme, themeProvider),
        ],
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme, TextTheme textTheme) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      pinned: false,
      backgroundColor: colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: Text(
          'Settings',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(
    ColorScheme colorScheme,
    TextTheme textTheme,
    ThemeData theme,
    ThemeProvider themeProvider,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),

        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader('Account', colorScheme, textTheme),

                _SettingsTile(
                  icon: Icons.person_outline_rounded,

                  title: 'Edit Profile',

                  subtitle: 'Update your personal information',

                  onTap: () {},

                  colorScheme: colorScheme,

                  textTheme: textTheme,
                ),

                _SettingsTile(
                  icon: Icons.lock_outline_rounded,

                  title: 'Change Password',

                  subtitle: 'Update your security credentials',

                  onTap: () {},

                  colorScheme: colorScheme,

                  textTheme: textTheme,
                ),

                _SettingsTile(
                  icon: Icons.notifications_outlined,

                  title: 'Notifications',

                  subtitle: 'Manage notification preferences',

                  onTap: () {},

                  colorScheme: colorScheme,

                  textTheme: textTheme,

                  trailing: Switch(
                    value: _notificationsEnabled,

                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                    },
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionHeader('Preferences', colorScheme, textTheme),

                _SettingsTile(
                  icon: Icons.dark_mode_outlined,

                  title: 'Dark Mode',

                  subtitle: 'Toggle app theme',

                  onTap: () {},

                  colorScheme: colorScheme,

                  textTheme: textTheme,

                  trailing: Switch(
                    value: theme.brightness == Brightness.dark,

                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                  ),
                ),

                _SettingsTile(
                  icon: Icons.language_rounded,

                  title: 'Language',

                  subtitle: 'English',

                  onTap: () {},

                  colorScheme: colorScheme,

                  textTheme: textTheme,
                ),

                _SettingsTile(
                  icon: Icons.inventory_outlined,

                  title: 'Default View',

                  subtitle: 'Choose default inventory view',

                  onTap: () {},

                  colorScheme: colorScheme,

                  textTheme: textTheme,
                ),

                const SizedBox(height: 24),

                _buildSectionHeader('House Group', colorScheme, textTheme),

                _SettingsTile(
                  icon: Icons.home_work_outlined,

                  title: 'My Groups',

                  subtitle: 'Manage your house groups',

                  onTap: () {},

                  colorScheme: colorScheme,

                  textTheme: textTheme,
                ),

                _SettingsTile(
                  icon: Icons.group_add_outlined,

                  title: 'Invite Members',

                  subtitle: 'Share group code with others',

                  onTap: () {},

                  colorScheme: colorScheme,

                  textTheme: textTheme,
                ),

                _SettingsTile(
                  icon: Icons.exit_to_app_rounded,

                  title: 'Leave Group',

                  subtitle: 'Exit current house group',

                  onTap: () {},

                  colorScheme: colorScheme,

                  textTheme: textTheme,

                  isDanger: true,
                ),

                const SizedBox(height: 24),

                _buildSectionHeader('Support', colorScheme, textTheme),

                _SettingsTile(
                  icon: Icons.help_outline_rounded,

                  title: 'Help & FAQ',

                  subtitle: 'Get answers to common questions',

                  onTap: () {},

                  colorScheme: colorScheme,

                  textTheme: textTheme,
                ),

                _SettingsTile(
                  icon: Icons.info_outline_rounded,

                  title: 'About',

                  subtitle: 'App version 1.0.0',

                  onTap: () {},

                  colorScheme: colorScheme,

                  textTheme: textTheme,
                ),

                _SettingsTile(
                  icon: Icons.policy_outlined,

                  title: 'Privacy Policy',

                  subtitle: 'Read our privacy terms',

                  onTap: () {},

                  colorScheme: colorScheme,

                  textTheme: textTheme,
                ),

                const SizedBox(height: 24),

                _buildSectionHeader('Danger Zone', colorScheme, textTheme),

                _SettingsTile(
                  icon: Icons.logout_rounded,

                  title: 'Log Out',

                  subtitle: 'Sign out of your account',

                  onTap: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },

                  colorScheme: colorScheme,

                  textTheme: textTheme,

                  isDanger: true,
                ),

                _SettingsTile(
                  icon: Icons.delete_outline_rounded,

                  title: 'Delete Account',

                  subtitle: 'Permanently remove your account',

                  onTap: () => _showDeleteAccountDialog(context),

                  colorScheme: colorScheme,

                  textTheme: textTheme,

                  isDanger: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await AuthService().deleteAccount();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting account: $e')));
        }
      }
    }
  }

  Widget _buildSectionHeader(
    String title,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
    this.trailing,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final Widget? trailing;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final tileColor = isDanger ? colorScheme.error : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: trailing == null ? onTap : null,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tileColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 22, color: tileColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDanger
                                    ? colorScheme.error
                                    : colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing ??
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colorScheme.onSurfaceVariant,
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
