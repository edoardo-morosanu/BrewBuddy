import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brewbuddy/utils/responsive.dart';
import 'package:brewbuddy/services/house_service.dart';
import 'package:brewbuddy/services/auth_service.dart';
import 'package:brewbuddy/ui/screens/auth_screen.dart';
import 'package:brewbuddy/ui/screens/house_group_intro_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key, this.isInMainScreen = false});

  final bool isInMainScreen;

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen>
    with TickerProviderStateMixin {
  late final AnimationController _headerController;
  late final AnimationController _fabController;
  bool _hasAnimated = false;
  bool _isLoading = true;
  String _groupName = '';
  String _groupCode = '';
  String _currentUserId = '';
  String? _houseId;
  bool _isCurrentUserAdmin = false;
  List<_Member> _members = [];
  int _totalItems = 0;
  int _itemsThisMonth = 0;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fetchGroupData();

    // Start animations only on first visit
    if (!_hasAnimated) {
      _hasAnimated = true;
      _headerController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _fabController.forward();
      });
    } else {
      // Skip animations, go to end state
      _headerController.value = 1.0;
      _fabController.value = 1.0;
    }
  }

  Future<void> _fetchGroupData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _currentUserId = user.id;
      }

      final house = await HouseService().getCurrentHouse();
      print('DEBUG: house data: $house');

      if (house != null) {
        setState(() {
          _houseId = house['id']?.toString();
          _groupName = house['name']?.toString() ?? '';
          _groupCode = house['invite_code']?.toString() ?? '';
        });

        final membersData = await HouseService().getHouseMembers(
          house['id'].toString(),
        );
        print('DEBUG: membersData: $membersData');

        // Fetch item counts
        final itemsResponse = await Supabase.instance.client
            .from('inventory_items')
            .select('created_by')
            .eq('house_id', house['id']);

        final itemCounts = <String, int>{};
        for (final item in itemsResponse) {
          final creator = item['created_by']?.toString();
          if (creator != null) {
            itemCounts[creator] = (itemCounts[creator] ?? 0) + 1;
          }
        }

        // Fetch this month's activity
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

        final historyResponse = await Supabase.instance.client
            .from('inventory_history')
            .select('id, inventory_items!inner(house_id)')
            .eq('inventory_items.house_id', house['id'])
            .gte('created_at', startOfMonth);

        setState(() {
          _totalItems = itemsResponse.length;
          _itemsThisMonth = historyResponse.length;
          final membersList = membersData.map((data) {
            print('DEBUG: processing member: $data');
            final profile = data['profiles'] != null
                ? data['profiles'] as Map<String, dynamic>
                : <String, dynamic>{};

            final userId = data['user_id']?.toString() ?? '';
            final role = (data['role']?.toString() ?? 'MEMBER').toUpperCase();
            final isAdmin = role == 'ADMIN';
            final isHead = role == 'HEAD';

            if (userId == _currentUserId) {
              _isCurrentUserAdmin = isAdmin || isHead;
            }

            return _Member(
              id: userId,
              name: profile['full_name']?.toString() ?? 'Unknown',
              email: profile['email']?.toString() ?? '',
              role: role,
              avatar: profile['avatar_url']?.toString() ?? '👤',
              joinedDate: _formatDate(data['joined_at']?.toString()),
              isAdmin: isAdmin,
              isHead: isHead,
              itemsAdded: itemCounts[userId] ?? 0,
            );
          }).toList();

          // Sort members: Head -> Admins -> Members (alphabetical within groups)
          membersList.sort((a, b) {
            if (a.isHead) return -1;
            if (b.isHead) return 1;

            if (a.isAdmin && !b.isAdmin) return -1;
            if (!a.isAdmin && b.isAdmin) return 1;

            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

          _members = membersList;
        });
      }
    } catch (e, stack) {
      print('Error fetching group data: $e');
      print(stack);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _headerController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Animated gradient background
                _buildAnimatedBackground(colorScheme),

                // Main content
                SafeArea(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Header
                      SliverToBoxAdapter(
                        child: _buildHeader(theme, colorScheme),
                      ),

                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: context.maxContentWidth,
                            ),
                            child: _buildGroupInfoCard(theme, colorScheme),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            MediaQuery.of(context).size.width >= 900
                                ? 40.0
                                : MediaQuery.of(context).size.width >= 600
                                ? 32.0
                                : 24.0,
                            32,
                            MediaQuery.of(context).size.width >= 900
                                ? 40.0
                                : MediaQuery.of(context).size.width >= 600
                                ? 32.0
                                : 24.0,
                            16,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.people_rounded,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Members',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_members.length}',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width >= 900
                              ? 40.0
                              : MediaQuery.of(context).size.width >= 600
                              ? 32.0
                              : 24.0,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: context.maxContentWidth,
                                ),
                                child: _buildMemberCard(
                                  _members[index],
                                  theme,
                                  colorScheme,
                                  index,
                                ),
                              ),
                            );
                          }, childCount: _members.length),
                        ),
                      ),

                      // Bottom spacing for FAB
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),

                // Floating action buttons
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _buildFloatingActions(theme, colorScheme),
                ),
              ],
            ),
    );
  }

  Widget _buildAnimatedBackground(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.3),
                colorScheme.secondaryContainer.withValues(alpha: 0.2),
                colorScheme.tertiaryContainer.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Animated orbs
              Positioned(
                top: -100 + (_headerController.value * 50),
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.15),
                        colorScheme.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 100 - (_headerController.value * 30),
                left: -100,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.tertiary.withValues(alpha: 0.15),
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

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _headerController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _headerController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.home_work_rounded,
                      color: colorScheme.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Group',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _groupName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Settings button
                  IconButton(
                    onPressed: _showGroupSettings,
                    icon: Icon(
                      Icons.settings_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
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

  Widget _buildGroupInfoCard(ThemeData theme, ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _headerController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
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
                  // Group code section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.key_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Group Code',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _groupCode,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copyGroupCode(colorScheme),
                        icon: Icon(
                          Icons.copy_rounded,
                          color: colorScheme.primary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stats row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: Icons.people_rounded,
                          label: 'Members',
                          value: '${_members.length}',
                          colorScheme: colorScheme,
                          theme: theme,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        _buildStatItem(
                          icon: Icons.inventory_2_rounded,
                          label: 'Items',
                          value: '$_totalItems',
                          colorScheme: colorScheme,
                          theme: theme,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        _buildStatItem(
                          icon: Icons.shopping_cart_rounded,
                          label: 'This Month',
                          value: '$_itemsThisMonth',
                          colorScheme: colorScheme,
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(
    _Member member,
    ThemeData theme,
    ColorScheme colorScheme,
    int index,
  ) {
    // Skip animations after first visit
    if (_hasAnimated) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: member.isAdmin
                      ? colorScheme.primary.withValues(alpha: 0.3)
                      : colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: member.isAdmin
                            ? [colorScheme.primary, colorScheme.secondary]
                            : [
                                colorScheme.primaryContainer,
                                colorScheme.secondaryContainer,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        member.avatar,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Member info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (member.isHead) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.amber, Colors.orange],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'HEAD',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ] else if (member.isAdmin) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ADMIN',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_rounded,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${member.itemsAdded} items',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              member.joinedDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // More button
                  IconButton(
                    onPressed: () => _showMemberOptions(member),
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Animate on first visit
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: member.isAdmin
                      ? colorScheme.primary.withValues(alpha: 0.3)
                      : colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: member.isAdmin
                            ? [colorScheme.primary, colorScheme.secondary]
                            : [
                                colorScheme.primaryContainer,
                                colorScheme.secondaryContainer,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        member.avatar,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Member info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (member.isHead) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.amber, Colors.orange],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'HEAD',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ] else if (member.isAdmin) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ADMIN',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_rounded,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${member.itemsAdded} items',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              member.joinedDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // More button
                  IconButton(
                    onPressed: () => _showMemberOptions(member),
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActions(ThemeData theme, ColorScheme colorScheme) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Share invite button
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: _shareInvite,
              heroTag: 'group_fab',
              backgroundColor: colorScheme.primary,
              icon: Icon(
                Icons.person_add_rounded,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                'Invite Member',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyGroupCode(ColorScheme colorScheme) {
    Clipboard.setData(ClipboardData(text: _groupCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: colorScheme.onPrimary),
            const SizedBox(width: 12),
            const Text('Group code copied to clipboard!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareInvite() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _InviteBottomSheet(groupName: _groupName, groupCode: _groupCode),
    );
  }

  void _showMemberOptions(_Member member) {
    // If current user is not admin, show nothing
    if (!_isCurrentUserAdmin) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Find current user's role
    final currentUser = _members.firstWhere(
      (m) => m.id == _currentUserId,
      orElse: () => _Member(
        id: '',
        name: '',
        email: '',
        role: '',
        avatar: '',
        joinedDate: '',
        isAdmin: false,
        isHead: false,
        itemsAdded: 0,
      ),
    );

    final isHead = currentUser.isHead;
    final isTargetHead = member.isHead;

    // Cannot perform actions on yourself via this menu
    if (member.id == _currentUserId) return;

    // If target is Head, nobody can kick them
    if (isTargetHead) return;

    // Logic for options
    final canKick = isHead || (currentUser.isAdmin && !member.isAdmin);
    final canPromote = !member.isAdmin && !member.isHead;
    final canTransferHead = isHead;

    if (!canKick && !canPromote && !canTransferHead) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Member info
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: member.avatar.startsWith('http')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              member.avatar,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Text(
                              member.avatar,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          member.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Options
              if (canPromote) ...[
                _buildOptionTile(
                  icon: Icons.admin_panel_settings_rounded,
                  label: 'Make Admin',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    if (_houseId == null) return;
                    try {
                      await HouseService().promoteToAdmin(_houseId!, member.id);
                      _fetchGroupData();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                const SizedBox(height: 8),
              ],

              if (canTransferHead) ...[
                _buildOptionTile(
                  icon: Icons.verified_user_rounded,
                  label: 'Make Head of House',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Transfer Ownership?'),
                        content: Text(
                          'Are you sure you want to make ${member.name} the Head of House? You will lose your Head status.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (_houseId == null) return;
                      try {
                        await HouseService().transferHeadRole(
                          _houseId!,
                          member.id,
                        );
                        _fetchGroupData();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  },
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                const SizedBox(height: 8),
              ],

              if (canKick) ...[
                _buildOptionTile(
                  icon: Icons.person_remove_rounded,
                  label: 'Kick from Group',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Kick Member?'),
                        content: Text(
                          'Are you sure you want to kick ${member.name}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.error,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Kick'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (_houseId == null) return;
                      try {
                        await HouseService().kickMember(_houseId!, member.id);
                        _fetchGroupData();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  },
                  colorScheme: colorScheme,
                  theme: theme,
                  isDestructive: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required ThemeData theme,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDestructive
              ? colorScheme.errorContainer.withValues(alpha: 0.3)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? colorScheme.error : colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isDestructive
                      ? colorScheme.error
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDestructive
                  ? colorScheme.error
                  : colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupSettings() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Find current user's role
    final currentUser = _members.firstWhere(
      (m) => m.id == _currentUserId,
      orElse: () => _Member(
        id: '',
        name: '',
        email: '',
        role: '',
        avatar: '',
        joinedDate: '',
        isAdmin: false,
        isHead: false,
        itemsAdded: 0,
      ),
    );

    final isHead = currentUser.isHead;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Group Settings',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // Options
              if (isHead) ...[
                _buildOptionTile(
                  icon: Icons.edit_rounded,
                  label: 'Edit Group Name',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showComingSoon('Edit group name');
                  },
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildOptionTile(
                  icon: Icons.refresh_rounded,
                  label: 'Regenerate Group Code',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showComingSoon('Regenerate code');
                  },
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildOptionTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete Group',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Group?'),
                        content: const Text(
                          'This action cannot be undone. All members will be removed.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.error,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (_houseId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error: House ID not found'),
                          ),
                        );
                        return;
                      }
                      try {
                        await HouseService().deleteHouse(_houseId!);
                        if (context.mounted) {
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const HouseGroupIntroScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  },
                  colorScheme: colorScheme,
                  theme: theme,
                  isDestructive: true,
                ),
                const SizedBox(height: 8),
              ],
              _buildOptionTile(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                colorScheme: colorScheme,
                theme: theme,
                isDestructive: false,
              ),
              const SizedBox(height: 8),
              _buildOptionTile(
                icon: Icons.exit_to_app_rounded,
                label: 'Leave Group',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Leave Group?'),
                      content: const Text(
                        'Are you sure you want to leave this group?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                          ),
                          child: const Text('Leave'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (_houseId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error: House ID not found'),
                        ),
                      );
                      return;
                    }
                    try {
                      await HouseService().leaveHouse(_houseId!);
                      if (context.mounted) {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const HouseGroupIntroScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
                colorScheme: colorScheme,
                theme: theme,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _InviteBottomSheet extends StatelessWidget {
  const _InviteBottomSheet({required this.groupName, required this.groupCode});

  final String groupName;
  final String groupCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_add_rounded,
                color: colorScheme.onPrimary,
                size: 48,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Invite to $groupName',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Share this code with friends to invite them to your group',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Group code display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Group Code',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    groupCode,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: groupCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Code copied!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy Code'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      // TODO: Implement share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Share functionality - Coming soon!',
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Member {
  final String id;
  final String name;
  final String email;
  final String role;
  final String avatar;
  final String joinedDate;
  final bool isAdmin;
  final bool isHead;
  final int itemsAdded;

  _Member({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.avatar,
    required this.joinedDate,
    required this.isAdmin,
    required this.isHead,
    required this.itemsAdded,
  });
}
