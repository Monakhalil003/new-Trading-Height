import 'package:flutter/material.dart';
import 'user_repository.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _repository = UserRepository();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  List<Map<String, dynamic>> get users => _users;

  // Getter for filtered users
  List<Map<String, dynamic>> get filteredUsers => _filteredUsers.isEmpty ? _users : _filteredUsers;

  Future<void> loadUsers() async {
  print("Loading users from database...");
  _users = await _repository.getUsers();
  _filteredUsers = List.from(_users);
  print("Loaded users: $_users");
  notifyListeners();
}

//add user
  Future<void> addUser(Map<String, dynamic> user) async {
  print("Received User: $user");

  if (user['name']?.trim().isEmpty ?? true) {
    print("Error: User name is empty");
    return;
  }

  if (user['timeLeft'] == null || user['timeLeft'].isEmpty) {
    print("Warning: timeLeft is missing. Setting default to 'Lifetime'.");
    user['timeLeft'] = 'Lifetime'; // Default value
  }

  print("Adding user with final data: $user");
  await _repository.addUser(user);
  await loadUsers();
  print("User added successfully!");
}


  // Delete user from the list
  Future<void> deleteUser(int id) async {
    await _repository.deleteUser(id);
    await loadUsers(); 
  }

  // Filter users based on search query
 void filterUsers(String query) {
  if (query.isEmpty) {
    _filteredUsers = List.from(_users);
  } else {
    _filteredUsers = _users
        .where((user) =>
            (user['name']?.toLowerCase() ?? '').contains(query.toLowerCase()) ||
            (user['id']?.toString() ?? '').contains(query))
        .toList();
  }
  notifyListeners();
}

  // Sort users based on the ascending or descending order
  void sortUsers(bool isAscending) {
    _users.sort((a, b) => isAscending
        ? (a['id'] ?? 0).compareTo(b['id'] ?? 0) 
        : (b['id'] ?? 0).compareTo(a['id'] ?? 0));
    _filteredUsers = List.from(_users); 
    notifyListeners(); 
  }

  // Get user by ID
  Map<String, dynamic> getUserById(int id) {
    return _users.firstWhere((user) => user['id'] == id, orElse: () => {});
  }
}
