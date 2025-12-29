import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../config/constants/app_constants.dart';
import '../models/user.dart';
import '../models/pee_log.dart';

/// Database service for SQLite operations
/// Handles all CRUD operations for User, PeeLog, and WaterIntake
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  /// Get database instance (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: 2, // Bumped version for schema change
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Pee logs table
    await db.execute('''
      CREATE TABLE pee_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_pee_logs_user_id ON pee_logs(user_id)');
    await db.execute(
      'CREATE INDEX idx_pee_logs_timestamp ON pee_logs(timestamp)',
    );
  }

  /// Handle database upgrades
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Destructive upgrade: Drop tables and recreate for new schema
      await db.execute('DROP TABLE IF EXISTS water_intakes');
      await db.execute('DROP TABLE IF EXISTS pee_logs');
      await db.execute('DROP TABLE IF EXISTS users');
      await _createDB(db, newVersion);
    }
  }

  // ============== USER OPERATIONS ==============

  /// Insert a new user
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  /// Get user by username
  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  /// Get user by ID
  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  // ============== PEE LOG OPERATIONS ==============

  /// Insert a new pee log
  Future<int> insertPeeLog(PeeLog log) async {
    final db = await database;
    return await db.insert('pee_logs', log.toMap());
  }

  /// Get all pee logs for a user ordered by timestamp
  Future<List<PeeLog>> getPeeLogs(int userId, {int? limit}) async {
    final db = await database;
    final maps = await db.query(
      'pee_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((map) => PeeLog.fromMap(map)).toList();
  }

  /// Get pee logs for a specific date
  Future<List<PeeLog>> getPeeLogsForDate(int userId, DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'pee_logs',
      where: 'user_id = ? AND timestamp >= ? AND timestamp < ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'timestamp ASC',
    );
    return maps.map((map) => PeeLog.fromMap(map)).toList();
  }

  /// Get pee logs for a date range
  Future<List<PeeLog>> getPeeLogsInRange(
    int userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'pee_logs',
      where: 'user_id = ? AND timestamp >= ? AND timestamp <= ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp ASC',
    );
    return maps.map((map) => PeeLog.fromMap(map)).toList();
  }

  /// Get daily pee count for a user
  Future<int> getDailyPeeCount(int userId, DateTime date) async {
    final logs = await getPeeLogsForDate(userId, date);
    return logs.length;
  }

  /// Get dates with pee logs in a month
  Future<Set<DateTime>> getPeeLogDatesInMonth(
    int userId,
    int year,
    int month,
  ) async {
    final db = await database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final maps = await db.query(
      'pee_logs',
      columns: ['timestamp'],
      where: 'user_id = ? AND timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        userId,
        startOfMonth.toIso8601String(),
        endOfMonth.toIso8601String(),
      ],
    );

    return maps.map((map) {
      final timestamp = DateTime.parse(map['timestamp'] as String);
      return DateTime(timestamp.year, timestamp.month, timestamp.day);
    }).toSet();
  }

  /// Delete a pee log
  Future<int> deletePeeLog(int id) async {
    final db = await database;
    return await db.delete('pee_logs', where: 'id = ?', whereArgs: [id]);
  }

  /// Update a pee log
  Future<int> updatePeeLog(PeeLog log) async {
    final db = await database;
    return await db.update(
      'pee_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  /// Get weekly pee frequency data
  Future<Map<DateTime, int>> getWeeklyPeeFrequency(int userId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final Map<DateTime, int> result = {};

    for (int i = 0; i < 7; i++) {
      final date = weekAgo.add(Duration(days: i + 1));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      result[normalizedDate] = await getDailyPeeCount(userId, normalizedDate);
    }

    return result;
  }

  /// Get total logs count for a user
  Future<int> getTotalPeeLogsCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pee_logs WHERE user_id = ?',
      [userId],
    );
    return result.first['count'] as int;
  }

  // ============== UTILITY ==============

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('pee_logs');
    await db.delete('users');
  }
}
