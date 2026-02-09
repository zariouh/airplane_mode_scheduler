import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule_model.dart';
import '../services/database_service.dart';
import '../services/alarm_service.dart';
import '../utils/logger.dart';

// Provider for the schedule list
final scheduleListProvider = StateNotifierProvider<ScheduleNotifier, AsyncValue<List<Schedule>>>((ref) {
  return ScheduleNotifier();
});

// Provider for active schedules only
final activeSchedulesProvider = Provider<AsyncValue<List<Schedule>>>((ref) {
  final schedules = ref.watch(scheduleListProvider);
  return schedules.when(
    data: (list) => AsyncValue.data(list.where((s) => s.isEnabled).toList()),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// Provider for today's schedules
final todaySchedulesProvider = Provider<AsyncValue<List<Schedule>>>((ref) {
  final schedules = ref.watch(scheduleListProvider);
  final today = DateTime.now().weekday - 1; // 0 = Monday
  
  return schedules.when(
    data: (list) => AsyncValue.data(
      list.where((s) => s.isEnabled && s.daysOfWeek[today]).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

class ScheduleNotifier extends StateNotifier<AsyncValue<List<Schedule>>> {
  final DatabaseService _db = DatabaseService();
  final AlarmService _alarm = AlarmService();

  ScheduleNotifier() : super(const AsyncValue.loading()) {
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      AppLogger.i('Loading schedules from database');
      final schedules = await _db.getAllSchedules();
      state = AsyncValue.data(schedules);
    } catch (e, stack) {
      AppLogger.e('Error loading schedules', e);
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSchedule(Schedule schedule) async {
    try {
      AppLogger.i('Adding schedule: ${schedule.name}');
      await _db.insertSchedule(schedule);
      
      // Schedule alarms if enabled
      if (schedule.isEnabled) {
        await _alarm.scheduleAirplaneModeToggle(schedule);
      }
      
      await _loadSchedules();
    } catch (e, stack) {
      AppLogger.e('Error adding schedule', e);
      throw Exception('Failed to add schedule: $e');
    }
  }

  Future<void> updateSchedule(Schedule schedule) async {
    try {
      AppLogger.i('Updating schedule: ${schedule.name}');
      await _db.updateSchedule(schedule);
      
      // Cancel existing alarms and reschedule if enabled
      await _alarm.cancelScheduleAlarms(schedule.id);
      if (schedule.isEnabled) {
        await _alarm.scheduleAirplaneModeToggle(schedule);
      }
      
      await _loadSchedules();
    } catch (e, stack) {
      AppLogger.e('Error updating schedule', e);
      throw Exception('Failed to update schedule: $e');
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      AppLogger.i('Deleting schedule: $id');
      await _alarm.cancelScheduleAlarms(id);
      await _db.deleteSchedule(id);
      await _loadSchedules();
    } catch (e, stack) {
      AppLogger.e('Error deleting schedule', e);
      throw Exception('Failed to delete schedule: $e');
    }
  }

  Future<void> toggleSchedule(String id, bool isEnabled) async {
    try {
      AppLogger.i('Toggling schedule $id: $isEnabled');
      final schedules = state.valueOrNull ?? [];
      final schedule = schedules.firstWhere((s) => s.id == id);
      final updated = schedule.copyWith(isEnabled: isEnabled);
      
      await _db.updateSchedule(updated);
      
      if (isEnabled) {
        await _alarm.scheduleAirplaneModeToggle(updated);
      } else {
        await _alarm.cancelScheduleAlarms(id);
      }
      
      await _loadSchedules();
    } catch (e, stack) {
      AppLogger.e('Error toggling schedule', e);
      throw Exception('Failed to toggle schedule: $e');
    }
  }

  Future<void> refresh() async {
    await _loadSchedules();
  }

  // Create Quick Sleep Mode schedule
  Future<void> createQuickSleepMode() async {
    const preset = QuickSleepPreset.defaultPreset;
    
    final schedule = Schedule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: preset.name,
      description: 'Automatically enable airplane mode at bedtime and disable at wake time',
      enableTime: preset.bedtime,
      disableTime: preset.wakeTime,
      daysOfWeek: preset.daysOfWeek,
      isEnabled: true,
      createdAt: DateTime.now(),
    );
    
    await addSchedule(schedule);
  }
}
