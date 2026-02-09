import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/schedule_model.dart';
import '../utils/constants.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get active days text
    final activeDays = _getActiveDaysText();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              icon: LucideIcons.pencil,
              label: 'Edit',
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              icon: LucideIcons.trash2,
              label: 'Delete',
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
            ),
          ],
        ),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: schedule.isEnabled
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusMd,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.plane,
                        color: schedule.isEnabled
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),

                    // Title and description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: schedule.isEnabled
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (schedule.description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              schedule.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Toggle switch
                    Switch(
                      value: schedule.isEnabled,
                      onChanged: onToggle,
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.spacingMd),

                // Time row
                Row(
                  children: [
                    _buildTimeChip(
                      context: context,
                      icon: LucideIcons.plane,
                      label: 'ON',
                      time: schedule.enableTime.format(),
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    const Icon(
                      LucideIcons.arrowRight,
                      size: 16,
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    _buildTimeChip(
                      context: context,
                      icon: LucideIcons.wifi,
                      label: 'OFF',
                      time: schedule.disableTime.format(),
                      color: colorScheme.tertiary,
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.spacingMd),

                // Days row
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activeDays,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            time,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _getActiveDaysText() {
    final allDaysSelected = schedule.daysOfWeek.every((day) => day);
    final noDaysSelected = schedule.daysOfWeek.every((day) => !day);
    final weekdaysSelected = schedule.daysOfWeek.sublist(0, 5).every((day) => day) &&
        schedule.daysOfWeek.sublist(5).every((day) => !day);
    final weekendsSelected = schedule.daysOfWeek.sublist(0, 5).every((day) => !day) &&
        schedule.daysOfWeek.sublist(5).every((day) => day);

    if (allDaysSelected) return 'Every day';
    if (noDaysSelected) return 'No days selected';
    if (weekdaysSelected) return 'Weekdays';
    if (weekendsSelected) return 'Weekends';

    // List individual days
    final activeDays = <String>[];
    for (int i = 0; i < 7; i++) {
      if (schedule.daysOfWeek[i]) {
        activeDays.add(AppConstants.dayNames[i]);
      }
    }

    if (activeDays.length <= 3) {
      return activeDays.join(', ');
    } else {
      return '${activeDays.length} days a week';
    }
  }
}
