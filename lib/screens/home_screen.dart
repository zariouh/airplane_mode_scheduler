import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';
import '../utils/constants.dart';
import '../widgets/quick_sleep_card.dart';
import '../widgets/schedule_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/bottom_nav_bar.dart';
import 'add_schedule_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final schedules = ref.watch(scheduleListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedules',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, MMM d').format(now),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openSettings(),
                      icon: const Icon(LucideIcons.settings),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    FilledButton.icon(
                      onPressed: () => _addNewSchedule(),
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMd,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Sleep Mode Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                ),
                child: QuickSleepCard(
                  onTap: () => _createQuickSleepSchedule(),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppConstants.spacingLg),
            ),

            // Upcoming Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                ),
                child: Row(
                  children: [
                    Text(
                      'Upcoming',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _refreshSchedules(),
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppConstants.spacingSm),
            ),

            // Schedules List
            schedules.when(
              data: (scheduleList) {
                if (scheduleList.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyState(),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final schedule = scheduleList[index];
                      return ScheduleCard(
                        schedule: schedule,
                        onToggle: (enabled) => _toggleSchedule(schedule.id, enabled),
                        onEdit: () => _editSchedule(schedule.id),
                        onDelete: () => _deleteSchedule(schedule.id),
                      );
                    },
                    childCount: scheduleList.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppConstants.spacingLg),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingLg),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.alertCircle,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: AppConstants.spacingMd),
                        Text(
                          'Error loading schedules',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          error.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppConstants.spacingXl),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNewSchedule(),
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Schedule'),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => _onNavTap(index),
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      // History tab - could show execution history
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('History feature coming soon!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _addNewSchedule() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddScheduleScreen(),
      ),
    );
  }

  void _editSchedule(String id) {
    // Navigate to edit screen with schedule ID
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddScheduleScreen(scheduleId: id),
      ),
    );
  }

  Future<void> _deleteSchedule(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule?'),
        content: const Text(
          'This action cannot be undone. The schedule will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(scheduleListProvider.notifier).deleteSchedule(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _toggleSchedule(String id, bool enabled) async {
    await ref.read(scheduleListProvider.notifier).toggleSchedule(id, enabled);
  }

  Future<void> _createQuickSleepSchedule() async {
    await ref.read(scheduleListProvider.notifier).createQuickSleepMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quick Sleep Mode schedule created!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _refreshSchedules() {
    ref.read(scheduleListProvider.notifier).refresh();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }
}
