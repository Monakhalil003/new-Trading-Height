import 'db_helper.dart'; 
import 'package:sqflite/sqflite.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

// Fetch all users from the database
Future<List<Map<String, dynamic>>> getUsers() async {
  final db = await _dbHelper.database;
  final users = await db.query('users'); // Retrieve data from database

  // Create mutable copies of the user maps
  final mutableUsers = users.map((user) => Map<String, dynamic>.from(user)).toList();

  // Add default values to ensure all keys are populated
  for (var user in mutableUsers) {
    user['id'] = user['id'] ?? 'NA';
    user['name'] = user['name'] ?? 'unknown';
    user['timeLeft'] = user['timeLeft'] ?? 'no date';
    user['note'] = user['note'] ?? 'N/A';
    user['endDate'] = user['endDate'] ?? 'N/A';
  }

  return mutableUsers;
}

  Future<void> addUser(Map<String, dynamic> user) async {
    try {
      user['actions'] = user['actions'] ?? '';
     
      final db = await _dbHelper.database;

      await db.insert(
        'users',
       user,
        conflictAlgorithm: ConflictAlgorithm.replace, 
      );

      print("User added to the database: $user");
    } catch (e) {
      print("Error adding user: $e");
      throw 'Failed to add user';
    }
  }

  // Fetch users from your data source (this may be a redundant function if the same functionality exists in getUsers)
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    
    return await getUsers();
  }

  // Delete a user by their ID
  Future<void> deleteUser(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'users', 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }
}