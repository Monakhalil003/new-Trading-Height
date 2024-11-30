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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(''' 
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        timeLeft TEXT NOT NULL,   -- Stores expiration timestamp as ISO string
        actions TEXT NOT NULL
      )
    ''');
  }

  // Insert user with validation for timeLeft
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;

    
    if (user['timeLeft'] == null || user['timeLeft'].isEmpty) {
      print('Error: timeLeft is null or empty for user: ${user['name']}');
      return -1; // Indicate failure
    }

    
    user['timeLeft'] = _calculateExpirationTimestamp(user['timeLeft']);
    
    print("Inserting user: $user");  
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


  // Get all valid users (filter expired)
Future<List<Map<String, dynamic>>> getUsers() async {
  final db = await database;
  final now = DateTime.now();

  final users = await db.query('users');

  print("Fetched users from database: $users");

  return users.where((user) {
    try {
      final timeLeft = user['timeLeft'] as String?;
      print("Processing user: ${user['id']}, timeLeft: $timeLeft");

      if (timeLeft == null || timeLeft.isEmpty) {
        print("Error: Invalid or missing timeLeft for user ${user['id']}");
        return false; 
      }

      final expiry = DateTime.parse(timeLeft);
      return expiry.isAfter(now); 
    } catch (e) {
      print("Error processing user ${user['id']}: $e");
      return false; 
    }
  }).toList();
}



  // Update user with validation for timeLeft
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

  // Delete user
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

  // Clear the entire database
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('users');
  }
}
