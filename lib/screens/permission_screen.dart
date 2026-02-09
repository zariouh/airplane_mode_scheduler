import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/permission_provider.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
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
                    _buildPermissionCard(
                      step: 1,
                      title: 'Exact Alarm Permission',
                      description: 'Required to schedule precise airplane mode toggles at the exact time you specify.',
                      icon: LucideIcons.alarmClock,
                      isGranted: permissionStatus.hasExactAlarmPermission,
                      onTap: () => _requestExactAlarmPermission(),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    _buildPermissionCard(
                      step: 2,
                      title: 'Battery Optimization Exemption',
                      description: 'Allows the app to run in the background and execute schedules even when the device is in power-saving mode.',
                      icon: LucideIcons.batteryCharging,
                      isGranted: permissionStatus.hasBatteryOptimizationExemption,
                      onTap: () => _requestBatteryOptimization(),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    _buildPermissionCard(
                      step: 3,
                      title: 'Airplane Mode Control',
                      description: 'Required to toggle airplane mode automatically. This requires a one-time ADB setup.',
                      icon: LucideIcons.plane,
                      isGranted: permissionStatus.hasWriteSecureSettings,
                      onTap: () => _showAdbInstructions(),
                      colorScheme: colorScheme,
                      isManualStep: true,
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

  Future<void> _requestExactAlarmPermission() async {
    await ref.read(permissionProvider.notifier).requestExactAlarmPermission();
  }

  Future<void> _requestBatteryOptimization() async {
    await ref.read(permissionProvider.notifier).requestBatteryOptimizationExemption();
  }

  Future<void> _requestNotificationPermission() async {
    await ref.read(permissionProvider.notifier).requestNotificationPermission();
  }

  void _showAdbInstructions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AdbInstructionsSheet(),
    );
  }

  void _continueToApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }
}

class AdbInstructionsSheet extends ConsumerWidget {
  const AdbInstructionsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.borderRadiusLg),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: AppConstants.spacingSm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ADB Setup Instructions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  children: [
                    _buildInfoCard(
                      colorScheme: colorScheme,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.info,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'What is ADB?',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Android Debug Bridge (ADB) is a command-line tool that lets you communicate with an Android device. This is a one-time setup that grants the app permission to control airplane mode.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    
                    Text(
                      'Setup Steps:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    
                    _buildStepCard(
                      step: 1,
                      title: 'Enable Developer Options',
                      description: 'Go to Settings > About Phone > tap "Build Number" 7 times until you see "You are now a developer!"',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    
                    _buildStepCard(
                      step: 2,
                      title: 'Enable USB Debugging',
                      description: 'Go to Settings > System > Developer Options > Enable "USB Debugging"',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    
                    _buildStepCard(
                      step: 3,
                      title: 'Download ADB Tools',
                      description: 'Download Android SDK Platform Tools from developer.android.com/studio/releases/platform-tools',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    
                    _buildStepCard(
                      step: 4,
                      title: 'Connect Your Device',
                      description: 'Connect your phone to your computer via USB and allow USB debugging when prompted',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    
                    _buildStepCard(
                      step: 5,
                      title: 'Run the ADB Command',
                      description: 'Open a terminal/command prompt in the platform-tools folder and run:',
                      colorScheme: colorScheme,
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMd,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                'adb shell pm grant com.airplane.scheduler android.permission.WRITE_SECURE_SETTINGS',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // Copy to clipboard
                                AppLogger.i('Copy command to clipboard');
                              },
                              icon: const Icon(LucideIcons.copy, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    
                    _buildStepCard(
                      step: 6,
                      title: 'Verify Permission',
                      description: 'Tap the button below to verify the permission was granted:',
                      colorScheme: colorScheme,
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await ref.read(permissionProvider.notifier)
                                .verifyWriteSecureSettingsPermission();
                          },
                          icon: const Icon(LucideIcons.checkCircle),
                          label: const Text('Verify Permission'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required ColorScheme colorScheme,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: child,
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required String description,
    required ColorScheme colorScheme,
    Widget? child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (child != null) child,
            ],
          ),
        ),
      ],
    );
  }
}
