import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/permission_provider.dart';
import '../services/airplane_mode_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';
  bool _isAirplaneModeOn = false;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _checkAirplaneModeStatus();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      AppLogger.e('Error loading app info', e);
    }
  }

  Future<void> _checkAirplaneModeStatus() async {
    final status = await AirplaneModeService.isAirplaneModeOn();
    setState(() {
      _isAirplaneModeOn = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final permissionStatus = ref.watch(permissionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Airplane Mode Status Card
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isAirplaneModeOn
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusMd,
                            ),
                          ),
                          child: Icon(
                            _isAirplaneModeOn
                                ? LucideIcons.plane
                                : LucideIcons.wifi,
                            color: _isAirplaneModeOn
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Airplane Mode',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _isAirplaneModeOn ? 'Currently ON' : 'Currently OFF',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isAirplaneModeOn,
                          onChanged: (value) => _toggleAirplaneMode(value),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Permissions Section
          _buildSectionHeader(context, 'Permissions'),
          ListTile(
            leading: Icon(
              LucideIcons.alarmClock,
              color: permissionStatus.hasExactAlarmPermission
                  ? colorScheme.primary
                  : colorScheme.error,
            ),
            title: const Text('Exact Alarm'),
            subtitle: Text(
              permissionStatus.hasExactAlarmPermission ? 'Granted' : 'Required',
            ),
            trailing: permissionStatus.hasExactAlarmPermission
                ? const Icon(LucideIcons.checkCircle, color: Colors.green)
                : const Icon(LucideIcons.alertCircle, color: Colors.orange),
            onTap: () => _requestExactAlarmPermission(),
          ),
          ListTile(
            leading: Icon(
              LucideIcons.batteryCharging,
              color: permissionStatus.hasBatteryOptimizationExemption
                  ? colorScheme.primary
                  : colorScheme.error,
            ),
            title: const Text('Battery Optimization'),
            subtitle: Text(
              permissionStatus.hasBatteryOptimizationExemption
                  ? 'Exempted'
                  : 'Required for background execution',
            ),
            trailing: permissionStatus.hasBatteryOptimizationExemption
                ? const Icon(LucideIcons.checkCircle, color: Colors.green)
                : const Icon(LucideIcons.alertCircle, color: Colors.orange),
            onTap: () => _requestBatteryOptimization(),
          ),
          ListTile(
            leading: Icon(
              LucideIcons.plane,
              color: permissionStatus.hasWriteSecureSettings
                  ? colorScheme.primary
                  : colorScheme.error,
            ),
            title: const Text('Airplane Mode Control'),
            subtitle: Text(
              permissionStatus.hasWriteSecureSettings
                  ? 'Granted'
                  : 'ADB setup required',
            ),
            trailing: permissionStatus.hasWriteSecureSettings
                ? const Icon(LucideIcons.checkCircle, color: Colors.green)
                : const Icon(LucideIcons.alertCircle, color: Colors.orange),
            onTap: () => _showAdbInstructions(),
          ),

          const Divider(),

          // Actions Section
          _buildSectionHeader(context, 'Actions'),
          ListTile(
            leading: const Icon(LucideIcons.refreshCw),
            title: const Text('Refresh Permissions'),
            subtitle: const Text('Check permission status again'),
            onTap: () => _refreshPermissions(),
          ),
          ListTile(
            leading: const Icon(LucideIcons.settings2),
            title: const Text('Open System Settings'),
            subtitle: const Text('Open app settings in Android'),
            onTap: () => AirplaneModeService.openAirplaneModeSettings(),
          ),

          const Divider(),

          // Test Toggle Button (NEW)
          ListTile(
            leading: const Icon(LucideIcons.plane, color: Colors.blue),
            title: const Text('Test Airplane Mode Toggle'),
            subtitle: const Text('ON → wait 5 seconds → OFF (diagnostic test)'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Turning Airplane Mode ON...')),
                );

                final successOn = await AirplaneModeService.toggleAirplaneMode(true);

                if (!successOn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to turn ON – check ADB permission'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                await Future.delayed(const Duration(seconds: 5));

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Turning Airplane Mode OFF...')),
                );

                final successOff = await AirplaneModeService.toggleAirplaneMode(false);

                if (successOff) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test toggle completed successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to turn OFF'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }

                // Refresh status after test
                await _checkAirplaneModeStatus();
              } catch (e) {
                AppLogger.e('Test toggle failed', e);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error during test: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
          ),

          const Divider(),

          // About Section
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(LucideIcons.info),
            title: const Text('Version'),
            subtitle: Text(_appVersion.isEmpty ? 'Loading...' : _appVersion),
          ),
          ListTile(
            leading: const Icon(LucideIcons.fileText),
            title: const Text('Open Source Licenses'),
            onTap: () => _showLicenses(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingSm,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _toggleAirplaneMode(bool enable) async {
    try {
      final success = await AirplaneModeService.toggleAirplaneMode(enable);
      if (success) {
        setState(() {
          _isAirplaneModeOn = enable;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                enable
                    ? 'Airplane mode enabled'
                    : 'Airplane mode disabled',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to toggle airplane mode. Please check permissions.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.e('Error toggling airplane mode', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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

  void _showAdbInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ADB Setup Required'),
        content: const Text(
          'To automatically control airplane mode, you need to grant WRITE_SECURE_SETTINGS permission via ADB.\n\n'
          'Run this command:\n'
          'adb shell pm grant com.airplane.scheduler android.permission.WRITE_SECURE_SETTINGS',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(permissionProvider.notifier).verifyWriteSecureSettingsPermission();
              Navigator.pop(context);
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshPermissions() async {
    await ref.read(permissionProvider.notifier).checkPermissions();
    await _checkAirplaneModeStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissions refreshed'),
        ),
      );
    }
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: _appVersion,
    );
  }
}
