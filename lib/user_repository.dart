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
    user['note'] = user['note'] ?? 'N/A';
    user['endTime'] = user['endTime'] ?? 'N/A';
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
  // Calculate the time left dynamically based on 'endTime'
  String _calculateTimeLeft(String endTime) {
    try {
      final endDateTime = DateTime.tryParse(endTime);
      final now = DateTime.now();
      
      if (endDateTime == null) {
        return "Invalid Date";  // If the endTime is invalid
      }

      if (endDateTime.isBefore(now)) {
        return "Expired";  // If the time has passed, it's expired
      }

      final difference = endDateTime.difference(now);
      if (difference.isNegative) {
        return "Expired"; // If somehow the difference is negative (edge case)
      }

      final hoursLeft = difference.inHours;
      final minutesLeft = difference.inMinutes % 60;

      // Returning a more readable format for the remaining time
      if (hoursLeft > 0) {
        return "$hoursLeft hours and $minutesLeft minutes left";
      } else {
        return "$minutesLeft minutes left";
      }
    } catch (e) {
      print("Error calculating time left: $e");
      return "Error";  // In case of any exception
    }
  }

  // Example of how you would use _calculateTimeLeft when displaying users
  List<Map<String, dynamic>> displayUsersWithTimeLeft(List<Map<String, dynamic>> users) {
    for (var user in users) {
      String endTime = user['endDate'] ?? '';  // endDate is used here, adjust if needed
      user['timeLeft'] = _calculateTimeLeft(endTime);  // Calculate time left dynamically
    }
    return users;
  }

}