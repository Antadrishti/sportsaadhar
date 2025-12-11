import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/models/leaderboard.dart';
import '../../core/services/progress_service.dart';
import '../../main.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;
  
  // Data for each tab
  LeaderboardData? _globalData;
  LeaderboardData? _regionalData;
  LeaderboardData? _ageGroupData;
  LeaderboardData? _genderData;
  LeaderboardData? _testData;
  
  // Test selection
  String _selectedTest = '30m_sprint';
  final List<Map<String, String>> _physicalTests = [
    {'id': '30m_sprint', 'name': '30m Sprint'},
    {'id': '800m_run', 'name': '800m Run'},
    {'id': '1600m_run', 'name': '1600m Run'},
    {'id': 'sit_ups', 'name': 'Sit-ups'},
    {'id': 'push_ups', 'name': 'Push-ups'},
    {'id': 'sit_and_reach', 'name': 'Sit and Reach'},
    {'id': '4x10_shuttle', 'name': '4×10m Shuttle Run'},
    {'id': 'standing_vertical_jump', 'name': 'Vertical Jump'},
    {'id': 'standing_broad_jump', 'name': 'Broad Jump'},
    {'id': 'medicine_ball_throw', 'name': 'Medicine Ball Throw'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadCurrentTabData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadCurrentTabData();
    }
  }

  Future<void> _loadCurrentTabData() async {
    final appState = context.read<AppState>();
    final user = appState.user;
    
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final progressService = context.read<ProgressService>();
      
      switch (_tabController.index) {
        case 0: // Global
          if (_globalData == null) {
            _globalData = await progressService.loadLeaderboard(
              LeaderboardType.global,
              userId: user.id,
            );
          }
          break;
        case 1: // Regional
          if (_regionalData == null && user.state != null) {
            _regionalData = await progressService.loadLeaderboard(
              LeaderboardType.regional,
              userId: user.id,
              filterValue: user.state,
            );
          }
          break;
        case 2: // Age Group
          if (_ageGroupData == null) {
            // Determine age group from user age
            final ageGroup = _getAgeGroup(user.age);
            _ageGroupData = await progressService.loadLeaderboard(
              LeaderboardType.ageGroup,
              userId: user.id,
              filterValue: ageGroup,
            );
          }
          break;
        case 3: // Gender
          if (_genderData == null && user.gender != null) {
            _genderData = await progressService.loadLeaderboard(
              LeaderboardType.gender,
              userId: user.id,
              filterValue: user.gender,
            );
          }
          break;
        case 4: // Test-specific
          _testData = await progressService.loadLeaderboard(
            LeaderboardType.test,
            userId: user.id,
            filterValue: _selectedTest,
          );
          break;
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getAgeGroup(int age) {
    if (age <= 12) return '10-12';
    if (age <= 15) return '13-15';
    if (age <= 18) return '16-18';
    if (age <= 25) return '19-25';
    return '26+';
  }

  Future<void> _refreshLeaderboard() async {
    // Clear cached data
    switch (_tabController.index) {
      case 0:
        _globalData = null;
        break;
      case 1:
        _regionalData = null;
        break;
      case 2:
        _ageGroupData = null;
        break;
      case 3:
        _genderData = null;
        break;
      case 4:
        _testData = null;
        break;
    }
    await _loadCurrentTabData();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view leaderboards'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Regional'),
            Tab(text: 'Age Group'),
            Tab(text: 'Gender'),
            Tab(text: 'Tests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardTab(_globalData, 'Global Rankings'),
          _buildLeaderboardTab(_regionalData, 'Regional Rankings'),
          _buildLeaderboardTab(_ageGroupData, 'Age Group Rankings'),
          _buildLeaderboardTab(_genderData, 'Gender Rankings'),
          _buildTestLeaderboardTab(),
        ],
      ),
    );
  }

  Widget _buildTestLeaderboardTab() {
    return Column(
      children: [
        // Test selector dropdown
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.white,
          child: DropdownButtonFormField<String>(
            value: _selectedTest,
            decoration: const InputDecoration(
              labelText: 'Select Test',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _physicalTests.map((test) {
              return DropdownMenuItem(
                value: test['id'],
                child: Text(test['name']!),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null && value != _selectedTest) {
                setState(() {
                  _selectedTest = value;
                  _testData = null; // Clear cached data
                });
                _loadCurrentTabData();
              }
            },
          ),
        ),
        Expanded(
          child: _buildLeaderboardTab(_testData, 'Test Rankings'),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTab(LeaderboardData? data, String title) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading leaderboard...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshLeaderboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (data == null) {
      return const Center(child: Text('No data available'));
    }

    if (data.topUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(
              'No rankings yet',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete tests to see rankings',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshLeaderboard,
      child: CustomScrollView(
        slivers: [
          // Top 3 Podium
          if (data.topUsers.length >= 3)
            SliverToBoxAdapter(
              child: _buildPodium(data.topUsers.take(3).toList())
                  .animate().fadeIn().slideY(begin: -0.1),
            ),

          // Remaining rankings (4+)
          if (data.topUsers.length > 3)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = data.topUsers[index + 3];
                    return _buildLeaderboardEntry(entry, index + 3)
                        .animate(delay: (index * 50).ms)
                        .fadeIn()
                        .slideX(begin: -0.1);
                  },
                  childCount: data.topUsers.length - 3,
                ),
              ),
            ),

          // User position (if not in top 50)
          if (data.userPosition != null && data.userPosition!.rank > 50)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildUserPositionCard(data.userPosition!)
                    .animate().fadeIn().scale(),
              ),
            ),

          // Spacing at bottom
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> topThree) {
    // Arrange in podium order: 2nd, 1st, 3rd
    final podiumOrder = topThree.length >= 3
        ? [topThree[1], topThree[0], topThree[2]]
        : topThree.length == 2
            ? [topThree[1], topThree[0]]
            : [topThree[0]];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (podiumOrder.length > 1)
            _buildPodiumPlace(podiumOrder[0], 2, 140),
          const SizedBox(width: 12),
          // 1st place
          _buildPodiumPlace(podiumOrder[0], 1, 160),
          const SizedBox(width: 12),
          // 3rd place
          if (podiumOrder.length > 2)
            _buildPodiumPlace(podiumOrder[2], 3, 120),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(LeaderboardEntry entry, int place, double height) {
    final colors = {
      1: AppColors.gold,
      2: AppColors.silver,
      3: AppColors.bronze,
    };
    
    final emojis = {
      1: '🥇',
      2: '🥈',
      3: '🥉',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Profile
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors[place]!.withValues(alpha: 0.1),
            border: Border.all(color: colors[place]!, width: 3),
          ),
          child: Center(
            child: Text(
              entry.name.substring(0, 1).toUpperCase(),
              style: AppTypography.titleLarge.copyWith(
                color: colors[place]!,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Name
        SizedBox(
          width: 90,
          child: Text(
            entry.name,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        // Score
        Text(
          '${entry.score}',
          style: AppTypography.titleSmall.copyWith(
            color: colors[place]!,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        // Podium
        Container(
          width: 90,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors[place]!.withValues(alpha: 0.8),
                colors[place]!,
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emojis[place]!,
                  style: const TextStyle(fontSize: 32),
                ),
                Text(
                  '#$place',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry, int index) {
    final appState = context.read<AppState>();
    final isCurrentUser = appState.user?.id == entry.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primaryOrange.withValues(alpha: 0.1)
            : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.primaryOrange
              : AppColors.lightBorder,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppColors.primaryOrange
                    : AppColors.gray200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '#${entry.rank}',
                  style: AppTypography.labelMedium.copyWith(
                    color: isCurrentUser
                        ? AppColors.white
                        : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrentUser
                    ? AppColors.primaryOrange.withValues(alpha: 0.2)
                    : AppColors.gray200,
              ),
              child: Center(
                child: Text(
                  entry.name.substring(0, 1).toUpperCase(),
                  style: AppTypography.titleSmall.copyWith(
                    color: isCurrentUser
                        ? AppColors.primaryOrange
                        : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.name,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.lightTextPrimary,
                            fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'YOU',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (entry.percentile != null)
                    Text(
                      'Top ${100 - entry.percentile!}%',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Score
            Text(
              '${entry.score}',
              style: AppTypography.titleMedium.copyWith(
                color: isCurrentUser
                    ? AppColors.primaryOrange
                    : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserPositionCard(LeaderboardEntry entry) {
    return SolidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person,
                color: AppColors.primaryOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Position',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLeaderboardEntry(entry, entry.rank - 1),
        ],
      ),
    );
  }
}
