
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
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
      version: 5,
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
      startTime TEXT,
      validity TEXT NOT NULL,
      actions TEXT, 
      note TEXT,
      endTime TEXT
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

    user['actions'] = user['actions'] ?? ''; // Ensure actions is not null

    // Set a default value for validity
    user['validity'] = user['validity'] ?? "valid";

    // Calculate expiration timestamp for timeLeft
    user['startTime'] = DateTime.now().toIso8601String();
    user['endTime'] = _calculateExpirationTimestamp(user['validity']);

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
  String _getValidity(String endTime) {
    if (endTime.contains("(valid)")) {
      return "valid";
    } else if (endTime.contains("(expired)")) {
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
    user['actions'] = user['actions'] ?? 'N/A';
    user['note'] = user['note'] ?? 'N/A';
    user['endTime'] = user['endTime'] ?? 'N/A';
    user['startTime'] = user['startTime'] ?? 'N/A';
    user['endTime'] = user['endTime'] ?? 'N/A';

     // Calculate the time left or check if expired
    String timeLeft = getTimeLeft(user['endTime']);
    user['timeLeft'] = timeLeft; 

    return user;
  }).where((user) {
    try {
      final endTime = user['endTime'] as String?;
      final validity = user['validity'] as String?;

      if (endTime == null || endTime.isEmpty || validity == null) {
        print("Error: Invalid or missing timeLeft/validity for user ${user['id']}");
        return false;
      }

      if (validity == "expired") return false;

      final expiry = DateTime.tryParse(endTime);
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
      user['endTime'] = _calculateExpirationTimestamp(user['validity']);

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

String getTimeLeft(String endTime) {
  final now = DateTime.now();
  final expiry = DateTime.tryParse(endTime);

  if (expiry == null) {
    
    return "Invalid date";
  }

  if (expiry.isBefore(now)) {
  
    return "Expired";
  }
  if (expiry.isAfter(now.add(Duration(days: 365 * 100)))) { 
  }

  // Calculate the remaining time
  final duration = expiry.difference(now);
  if (duration.inDays > 0) {
    return "${duration.inDays} day${duration.inDays > 1 ? 's' : ''} left";
  } else if (duration.inHours > 0) {
    return "${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} left";
  } else if (duration.inMinutes > 0) {
    return "${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} left";
  } else {
    return "Less than a minute left";
  }
}
Future<void> initializeNotifications() async {
 
  await AwesomeNotifications().initialize(
    'resource://drawable/res_app_icon', 
    [
      NotificationChannel(
        channelKey: 'expiry_notifications', 
        channelName: 'Expiry Notifications', 
        channelDescription: 'Notify about expiring subscriptions', 
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white, 
        importance: NotificationImportance.High, 
        
      ),
    ],
  );
}
Future<void> showNotification({
  required int id,
  required String title,
  required String body,
}) async {

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: id, 
      channelKey: 'expiry_notifications',
      title: title, 
      body: body, 
      notificationLayout: NotificationLayout.Default, 
      
    ),
  );
}


Future<void> checkAndNotifyUsers() async {
  final db = await database;
  final users = await db.query('users'); 

  final now = DateTime.now();

  for (var user in users) {
    print('User  data: $user');

    
    if (user['id'] == null || user['endTime'] == null) {
      print('User  ID or endTime is null for user: $user');
      continue; 
    }

    DateTime? endTime;
    try {
      endTime = DateTime.tryParse(user['endTime'] as String);
      if (endTime == null) {
        print('Error parsing endTime for user: ${user['name']}');
        continue; 
      }
    } catch (e) {
      print('Error parsing endTime for user: ${user['name']}, error: $e');
      continue; 
    }

    final duration = endTime.difference(now);
    final daysLeft = duration.inDays;

    if (duration.isNegative) {
      
      await showNotification(
        id: user['id'] as int, 
        title: 'Subscription Expired',
        body: '${user['name']}, your subscription has expired!',
      );
    } else if (daysLeft < 3) {
      
      await showNotification(
        id: user['id'] as int, 
        title: 'Subscription Expiry Reminder',
        body: '${user['name']}, your subscription will expire in $daysLeft days!',
      );
    }
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
      where: 'endTime < ?',
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
    await db.execute('ALTER TABLE users ADD startTime TEXT');
  }
  if (oldVersion < 4) {
    await db.execute('ALTER TABLE users ADD endTime TEXT');
  }

  print("Database upgraded to version $newVersion. Schema:");
  List<Map<String, dynamic>> result = await db.rawQuery("PRAGMA table_info(users);");
  print(result);
}
}