import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/speed_violation.dart';

class DatabaseHelper {
  // Singleton pattern: no matter how many times DatabaseHelper() is called,
  // anywhere in the app, it always returns this exact same instance, wrapping
  // one single open connection to the database file. Without this, two
  // different screens calling DatabaseHelper() could each open their own
  // separate connection to the same file, which causes real, hard-to-debug
  // data problems.
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'selfsnitch.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE violations(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            speedMph REAL NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertViolation(SpeedViolation violation) async {
    final db = await _db;
    await db.insert('violations', violation.toMap());
  }

  Future<List<SpeedViolation>> getAllViolations() async {
    final db = await _db;
    final rows = await db.query('violations', orderBy: 'timestamp ASC');
    return rows.map((row) => SpeedViolation.fromMap(row)).toList();
  }
}
