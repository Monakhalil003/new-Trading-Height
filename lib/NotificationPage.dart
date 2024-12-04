import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'db_helper.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    checkAndNotifyUsers(); 
  }

 
  Future<void> checkAndNotifyUsers() async {
    final db = await dbHelper.database; 
    final users = await db.query('users'); 

    final now = DateTime.now();
    List<Map<String, dynamic>> newNotifications = [];

    for (var user in users) {
      print('User data: $user');

      if (user['id'] == null || user['endTime'] == null) {
        print('User ID or endTime is null for user: $user');
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
        newNotifications.add({
          'id': user['id'],
          'name': user['name'],
          'message': '${user['name']}, your subscription has expired!',
          'timeLeft': "Expired",
        });
      } else if (daysLeft < 3) {
        newNotifications.add({
          'id': user['id'],
          'name': user['name'],
          'message': '${user['name']}, your subscription will expire in $daysLeft days!',
          'timeLeft': "$daysLeft days left",
        });
      }
    }

    // Update the UI with the new notifications
    setState(() {
      notifications = newNotifications;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Notifications',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              color: const Color(0xFFFFA600),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        backgroundColor: const Color(0xFF273562),
    
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: const Color.fromARGB(255, 39, 53, 98),
              child: notifications.isEmpty
                  ? const Center(
                      child: Text(
                        "No notifications to show.",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final timeLeft = notification['timeLeft'] ?? "Expired";

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 4,
                          child: ListTile(
                            leading: const Icon(Icons.notifications, color: Colors.blue),
                            title: const Text(
                              "Expiry Alert",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              notification['message'] ?? "No details available",
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            trailing: Text(
                              timeLeft,
                              style: TextStyle(
                                color: timeLeft == "Expired" ? Colors.red : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
