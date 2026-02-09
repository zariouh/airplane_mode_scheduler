import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class AddScheduleScreen extends ConsumerStatefulWidget {
  final String? scheduleId;

  const AddScheduleScreen({super.key, this.scheduleId});

  @override
  ConsumerState<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends ConsumerState<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  TimeOfDay _enableTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _disableTime = const TimeOfDay(hour: 7, minute: 0);
  List<bool> _selectedDays = [true, true, true, true, true, true, true];
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.scheduleId != null) {
      _isEditing = true;
      _loadSchedule();
    }
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      final schedule = await DatabaseService().getSchedule(widget.scheduleId!);
      if (schedule != null && mounted) {
        setState(() {
          _nameController.text = schedule.name;
          _descriptionController.text = schedule.description ?? '';
          _enableTime = TimeOfDay(
            hour: schedule.enableTime.hour,
            minute: schedule.enableTime.minute,
          );
          _disableTime = TimeOfDay(
            hour: schedule.disableTime.hour,
            minute: schedule.disableTime.minute,
          );
          _selectedDays = List.from(schedule.daysOfWeek);
        });
      }
    } catch (e) {
      AppLogger.e('Error loading schedule', e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Schedule' : 'New Schedule'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.spacingMd),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: () => _saveSchedule(),
              icon: const Icon(LucideIcons.check),
              label: Text(_isEditing ? 'Update' : 'Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                children: [
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Schedule Name',
                      hintText: 'e.g., Sleep Mode, Work Hours',
                      prefixIcon: Icon(LucideIcons.tag),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingMd),

                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add a note about this schedule',
                      prefixIcon: Icon(LucideIcons.fileText),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  // Time Selection Section
                  _buildSectionHeader(
                    context,
                    'Time Settings',
                    LucideIcons.clock,
                  ),
                  const SizedBox(height: AppConstants.spacingMd),

                  // Enable time (Airplane mode ON)
                  _buildTimeSelector(
                    context: context,
                    label: 'Enable Airplane Mode',
                    subtitle: 'Airplane mode will turn ON at this time',
                    icon: LucideIcons.plane,
                    iconColor: colorScheme.primary,
                    time: _enableTime,
                    onTap: () => _selectTime(context, true),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),

                  // Disable time (Airplane mode OFF)
                  _buildTimeSelector(
                    context: context,
                    label: 'Disable Airplane Mode',
                    subtitle: 'Airplane mode will turn OFF at this time',
                    icon: LucideIcons.wifi,
                    iconColor: colorScheme.tertiary,
                    time: _disableTime,
                    onTap: () => _selectTime(context, false),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  // Days of week section
                  _buildSectionHeader(
                    context,
                    'Repeat',
                    LucideIcons.calendar,
                  ),
                  const SizedBox(height: AppConstants.spacingMd),

                  // Day selector chips
                  Wrap(
                    spacing: AppConstants.spacingSm,
                    runSpacing: AppConstants.spacingSm,
                    children: List.generate(7, (index) {
                      final dayName = AppConstants.dayNames[index];
                      final isSelected = _selectedDays[index];

                      return FilterChip(
                        label: Text(dayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedDays[index] = selected;
                          });
                        },
                        selectedColor: colorScheme.primaryContainer,
                        checkmarkColor: colorScheme.onPrimaryContainer,
                      );
                    }),
                  ),
                  const SizedBox(height: AppConstants.spacingSm),

                  // Select all / Clear all buttons
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedDays = [true, true, true, true, true, true, true];
                          });
                        },
                        icon: const Icon(LucideIcons.checkSquare, size: 16),
                        label: const Text('Select All'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedDays = [false, false, false, false, false, false, false];
                          });
                        },
                        icon: const Icon(LucideIcons.square, size: 16),
                        label: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  // Info card
                  _buildInfoCard(context),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                  vertical: AppConstants.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                ),
                child: Text(
                  time.format(context),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.info,
            size: 20,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              'Make sure you have granted all required permissions for the app to automatically toggle airplane mode.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isEnableTime) async {
    final initialTime = isEnableTime ? _enableTime : _disableTime;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false,
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        if (isEnableTime) {
          _enableTime = pickedTime;
        } else {
          _disableTime = pickedTime;
        }
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate at least one day is selected
    if (!_selectedDays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final schedule = Schedule(
        id: _isEditing ? widget.scheduleId! : const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        enableTime: TimeOfDayInfo(
          hour: _enableTime.hour,
          minute: _enableTime.minute,
        ),
        disableTime: TimeOfDayInfo(
          hour: _disableTime.hour,
          minute: _disableTime.minute,
        ),
        daysOfWeek: _selectedDays,
        isEnabled: true,
        createdAt: DateTime.now(),
      );

      if (_isEditing) {
        await ref.read(scheduleListProvider.notifier).updateSchedule(schedule);
      } else {
        await ref.read(scheduleListProvider.notifier).addSchedule(schedule);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Schedule updated successfully'
                : 'Schedule created successfully'),
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error saving schedule', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
