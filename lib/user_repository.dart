import 'db_helper.dart'; 
import 'package:sqflite/sqflite.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Fetch all users from the database
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await _dbHelper.database;
    return await db.query('users');
  }

  // Add a user to the database
  Future<void> addUser (Map<String, dynamic> user) async {
  final db = await _dbHelper.database;
  await db.insert(
    'users', 
    user, 
    conflictAlgorithm: ConflictAlgorithm.replace
  );
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
