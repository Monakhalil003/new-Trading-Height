import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    } else {
      _database = await _initDatabase();
      return _database!;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'my_database.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, 
    );
  }

//user tavbke
 Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      timeLeft TEXT NOT NULL,
      validity TEXT NOT NULL,
       actions TEXT, 
      note TEXT,
      endDate TEXT -- Include the endDate column here
    )
  ''');
  
  print("Table created. Schema:");
  List<Map<String, dynamic>> result = await db.rawQuery("PRAGMA table_info(users);");
  print(result); 


}

  // Insert a user with validation for timeLeft
 Future<int> insertUser(Map<String, dynamic> user) async {
  final db = await database;

// Log the user data before insertion
  print("Inserting user: $user");
  if (user['timeLeft'] == null || user['timeLeft'].isEmpty) {
    print('Error: timeLeft is null or empty for user: ${user['name']}');
    return -1; 
  }
  user['actions'] = user['actions'] ?? ''; 
 
  String validity = user['validity'] ?? "valid";
  user['validity'] = validity;
  
  
  user['timeLeft'] = _calculateExpirationTimestamp(user['timeLeft']);

  print("Inserting user with data: $user");
  return await db.insert('users', user);
}

  // Calculate expiration timestamp for timeLeft
  String _calculateExpirationTimestamp(String timeLeft) {
    final now = DateTime.now();

    if (timeLeft.contains('day')) {
      final days = int.tryParse(timeLeft.split(' ')[0]) ?? 0;
      return now.add(Duration(days: days)).toIso8601String();
    } else if (timeLeft.contains('min')) {
      final minutes = int.tryParse(timeLeft.split(' ')[0]) ?? 0;
      return now.add(Duration(minutes: minutes)).toIso8601String();
    } else if (timeLeft.contains('Lifetime')) {
      return DateTime(9999, 12, 31).toIso8601String();
    } else {
      print('Error: Invalid timeLeft format: $timeLeft');
      return DateTime.now().toIso8601String(); 
    }
  }

  // Extract validity from timeLeft
  String _getValidity(String timeLeft) {
    if (timeLeft.contains("(valid)")) {
      return "valid";
    } else if (timeLeft.contains("(expired)")) {
      return "expired";
    }
    return "unknown"; 
  }

// Get all valid users (filter expired)
Future<List<Map<String, dynamic>>> getUsers() async {
  final db = await database;
  final now = DateTime.now();

  final users = await db.query('users'); 
  print("Fetched users from database: $users");

  final mutableUsers = users.map((user) => Map<String, dynamic>.from(user)).toList();

  return mutableUsers.map((user) {
    user['id'] = user['id'] ?? 'NA';
    user['name'] = user['name'] ?? 'unknown';
    user['timeLeft'] = user['timeLeft'] ?? 'no date';
    user['actions'] = user['actions'] ?? 'N/A';
    user['note'] = user['note'] ?? 'N/A';
    user['endDate'] = user['endDate'] ?? 'N/A';
    return user;
  }).where((user) {
    try {
      final timeLeft = user['timeLeft'] as String?;
      final validity = user['validity'] as String?;

      if (timeLeft == null || timeLeft.isEmpty || validity == null) {
        print("Error: Invalid or missing timeLeft/validity for user ${user['id']}");
        return false;
      }

      if (validity == "expired") return false;

      final expiry = DateTime.tryParse(timeLeft);
      return expiry != null && expiry.isAfter(now);
    } catch (e) {
      print("Error processing user ${user['id']}: $e");
      return false;
    }
  }).toList();
}

  // Update a user with validation for timeLeft
  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await database;

    try {
      if (user['timeLeft'] == null || user['timeLeft'].isEmpty) {
        print('Error: timeLeft is null or empty for user: ${user['name']}');
        return -1; 
      }

      user['timeLeft'] = _calculateExpirationTimestamp(user['timeLeft']);

      return await db.update(
        'users',
        user,
        where: 'id = ?',
        whereArgs: [user['id']],
      );
    } catch (error) {
      print('Error updating user: $error');
      return -1;
    }
  }

  // Delete a user by ID
  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clean up expired users 
  Future<void> cleanUpExpiredUsers() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.delete(
      'users',
      where: 'timeLeft < ?',
      whereArgs: [now],
    );
  }

  // Clear all users from the database 
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('users');
  }

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE users ADD COLUMN note TEXT');
  }
  if (oldVersion < 3) {
    await db.execute('ALTER TABLE users ADD COLUMN endDate TEXT');
  }
 
  print("Database upgraded to version $newVersion. Schema:");
  List<Map<String, dynamic>> result = await db.rawQuery("PRAGMA table_info(users);");
  print(result);
}
}