import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/schedule_model.dart';
import '../utils/logger.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'airplane_scheduler.db';
  static const int _databaseVersion = 1;

  // Table name
  static const String tableSchedules = 'schedules';

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);

      AppLogger.i('Initializing database at: $path');

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      AppLogger.e('Error initializing database', e);
      throw Exception('Failed to initialize database: $e');
    }
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    try {
      AppLogger.i('Creating database tables');
      
      await db.execute('''
        CREATE TABLE $tableSchedules (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          enableTime TEXT NOT NULL,
          disableTime TEXT NOT NULL,
          daysOfWeek TEXT NOT NULL,
          isEnabled INTEGER NOT NULL DEFAULT 1,
          createdAt TEXT NOT NULL,
          lastExecuted TEXT
        )
      ''');

      AppLogger.i('Database tables created successfully');
    } catch (e) {
      AppLogger.e('Error creating database tables', e);
      throw Exception('Failed to create tables: $e');
    }
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.i('Upgrading database from $oldVersion to $newVersion');
    // Handle future migrations here
  }

  // Insert a new schedule
  Future<void> insertSchedule(Schedule schedule) async {
    try {
      final db = await database;
      await db.insert(
        tableSchedules,
        schedule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.i('Schedule inserted: ${schedule.id}');
    } catch (e) {
      AppLogger.e('Error inserting schedule', e);
      throw Exception('Failed to insert schedule: $e');
    }
  }

  // Get all schedules
  Future<List<Schedule>> getAllSchedules() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableSchedules,
        orderBy: 'createdAt DESC',
      );

      return List.generate(maps.length, (i) {
        return Schedule.fromMap(maps[i]);
      });
    } catch (e) {
      AppLogger.e('Error getting all schedules', e);
      throw Exception('Failed to get schedules: $e');
    }
  }

  // Get a single schedule by ID
  Future<Schedule?> getSchedule(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableSchedules,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return Schedule.fromMap(maps.first);
    } catch (e) {
      AppLogger.e('Error getting schedule', e);
      throw Exception('Failed to get schedule: $e');
    }
  }

  // Update a schedule
  Future<void> updateSchedule(Schedule schedule) async {
    try {
      final db = await database;
      await db.update(
        tableSchedules,
        schedule.toMap(),
        where: 'id = ?',
        whereArgs: [schedule.id],
      );
      AppLogger.i('Schedule updated: ${schedule.id}');
    } catch (e) {
      AppLogger.e('Error updating schedule', e);
      throw Exception('Failed to update schedule: $e');
    }
  }

  // Delete a schedule
  Future<void> deleteSchedule(String id) async {
    try {
      final db = await database;
      await db.delete(
        tableSchedules,
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.i('Schedule deleted: $id');
    } catch (e) {
      AppLogger.e('Error deleting schedule', e);
      throw Exception('Failed to delete schedule: $e');
    }
  }

  // Get enabled schedules only
  Future<List<Schedule>> getEnabledSchedules() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableSchedules,
        where: 'isEnabled = ?',
        whereArgs: [1],
      );

      return List.generate(maps.length, (i) {
        return Schedule.fromMap(maps[i]);
      });
    } catch (e) {
      AppLogger.e('Error getting enabled schedules', e);
      throw Exception('Failed to get enabled schedules: $e');
    }
  }

  // Update last executed time
  Future<void> updateLastExecuted(String id, DateTime time) async {
    try {
      final db = await database;
      await db.update(
        tableSchedules,
        {'lastExecuted': time.toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.i('Last executed updated for: $id');
    } catch (e) {
      AppLogger.e('Error updating last executed', e);
    }
  }

  // Close database
  Future<void> close() async {
    try {
      final db = await database;
      await db.close();
      _database = null;
      AppLogger.i('Database closed');
    } catch (e) {
      AppLogger.e('Error closing database', e);
    }
  }
}
