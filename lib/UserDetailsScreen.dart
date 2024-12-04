import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'userViewModel.dart';

class UserDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> member;

   const UserDetailsScreen({Key? key, required this.member}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('User Details',
          style: GoogleFonts.montserrat(
              fontSize: 22,
              color: const Color(0xFFFFA600),
              fontWeight: FontWeight.bold,),
        ),
        centerTitle: true,
        backgroundColor:  const Color(0xFF273562), 
      ),
      body: Container(
        color: const Color.fromARGB(255, 39, 53, 98), 
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Name',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFFFA600)),
            ),
            Text(
              '${member['name'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 20), 

            const Text(
              'Start Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFFFA600)),
            ),
            Text(
              '${member['startTime'] ?? 'xx/xx/xxxx'}',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 20), 

            const Text(
              'Days Left',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFFFA600)),
            ),
            Text(
              '${member['endTime'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 20), 

            const Text(
              'Expected End Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFFFA600)),
            ),
            Text(
              '${member['endTime'] ?? 'xx/xx/xxxx'}',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 20), 

            const Text(
              'Note',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFFFA600)),
            ),
            Text(
              '${member['note'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 18, color: const Color(0xFFFFA600)),
            ),
            const SizedBox(height: 20), 

           
            const Spacer(),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA600), 
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
