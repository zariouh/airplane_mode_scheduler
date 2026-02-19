import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/permission_provider.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import '../services/airplane_mode_service.dart'; // ADD THIS IMPORT
import 'home_screen.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final permissionStatus = ref.watch(permissionProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Setup Required',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                'To automatically schedule airplane mode, the app needs the following permissions:',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              
              // Permission steps
              Expanded(
                child: ListView(
                  children: [
                    // ADDED: SCHEDULE_EXACT_ALARM permission (Critical for Android 14+)
                    _buildPermissionCard(
                      step: 1,
                      title: 'Schedule Exact Alarms',
                      description: 'CRITICAL: Required to schedule precise airplane mode toggles at the exact time. Android 14+ requires this permission.',
                      icon: LucideIcons.alarmClock,
                      isGranted: permissionStatus.hasScheduleExactAlarmPermission,
                      onTap: () => _requestScheduleExactAlarmPermission(),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    _buildPermissionCard(
                      step: 2,
                      title: 'Exact Alarm Permission',
                      description: 'Required to schedule precise airplane mode toggles at the exact time you specify.',
                      icon: LucideIcons.timer,
                      isGranted: permissionStatus.hasExactAlarmPermission,
                      onTap: () => _requestExactAlarmPermission(),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    _buildPermissionCard(
                      step: 3,
                      title: 'Battery Optimization Exemption',
                      description: 'Allows the app to run in the background and execute schedules even when the device is in power-saving mode.',
                      icon: LucideIcons.batteryCharging,
                      isGranted: permissionStatus.hasBatteryOptimizationExemption,
                      onTap: () => _requestBatteryOptimization(),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    _buildPermissionCard(
                      step: 4,
                      title: 'Notification Permission',
                      description: 'Optional - allows the app to show notifications when airplane mode is toggled.',
                      icon: LucideIcons.bell,
                      isGranted: permissionStatus.hasNotificationPermission,
                      onTap: () => _requestNotificationPermission(),
                      colorScheme: colorScheme,
                      isOptional: true,
                    ),
                  ],
                ),
              ),
              
              // Continue button
              if (permissionStatus.isAllGranted)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _continueToApp(),
                    icon: const Icon(LucideIcons.arrowRight),
                    label: const Text('Continue to App'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(AppConstants.spacingMd),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required int step,
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    bool isManualStep = false,
    bool isOptional = false,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isGranted ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            children: [
              // Step number or checkmark
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isGranted
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isGranted
                      ? Icon(
                          LucideIcons.check,
                          color: colorScheme.primary,
                          size: 20,
                        )
                      : Text(
                          '$step',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isGranted
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isOptional)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Optional',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isManualStep && !isGranted) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tap for setup instructions',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action icon
              Icon(
                isGranted
                    ? LucideIcons.checkCircle2
                    : isManualStep
                        ? LucideIcons.helpCircle
                        : LucideIcons.chevronRight,
                color: isGranted
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ADDED: Request SCHEDULE_EXACT_ALARM permission
  Future<void> _requestScheduleExactAlarmPermission() async {
    final granted = await AirplaneModeService.requestScheduleExactAlarmPermission();
    if (granted) {
      // Refresh permission state
      ref.read(permissionProvider.notifier).refreshPermissions();
    } else {
      // Show dialog explaining how to enable manually
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Please allow "Alarms & reminders" permission in the next screen. '
              'This is required for the app to schedule airplane mode toggles.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    await ref.read(permissionProvider.notifier).requestExactAlarmPermission();
  }

  Future<void> _requestBatteryOptimization() async {
    await ref.read(permissionProvider.notifier).requestBatteryOptimizationExemption();
  }

  Future<void> _requestNotificationPermission() async {
    await ref.read(permissionProvider.notifier).requestNotificationPermission();
  }

  void _continueToApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }
}
