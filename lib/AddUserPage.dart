import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'userViewModel.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _validityController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  void setValidity(String validity) {
    setState(() {
      _validityController.text = validity;
      final currentDate = DateTime.now();

      if (validity == '30 Days') {
        _endTimeController.text =
            DateFormat('MM/dd/yyyy').format(currentDate.add(Duration(days: 30)));
      } else if (validity == '1 Year') {
        _endTimeController.text = DateFormat('MM/dd/yyyy').format(
            DateTime(currentDate.year + 1, currentDate.month, currentDate.day));
      } else if (validity == 'Lifetime') {
        _endTimeController.text = 'Lifetime';
      } else if (validity == '10 mins') {
        _endTimeController.text = DateFormat('MM/dd/yyyy HH:mm')
            .format(currentDate.add(Duration(minutes: 10)));
      }else if (validity == '2 mins') {
        _endTimeController.text = DateFormat('MM/dd/yyyy HH:mm')
            .format(currentDate.add(Duration(minutes: 2)));
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _validityController.dispose();
    _noteController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
            'Add User',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              color: const Color(0xFFFFA600),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        backgroundColor: const Color(0xFF273562),
    
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Name', 'User\'s Name', _nameController),
              _buildValidityButtons(),
              _buildTextField('Selected Validity', 'Selected Validity',
                  _validityController, readOnly: true),
              _buildTextField('Additional Note', 'Add a note or leave empty',
                  _noteController, maxLines: 7),
              _buildTextField('Expected End Date', 'xx/xx/xxxx',
                  _endTimeController, readOnly: true),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _addUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 80, vertical: 20),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hintText,
      TextEditingController controller,
      {bool readOnly = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 24,
            color: const Color(0xFFFFA600),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color.fromARGB(255, 241, 238, 94)),
            ),
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildValidityButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ['30 Days', '1 Year', 'Lifetime', '10 mins','2mins']
          .map((validity) => OutlinedButton(
                onPressed: () => setValidity(validity),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: Color.fromARGB(255, 241, 238, 94)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  validity,
                  style: const TextStyle(color: Colors.white),
                ),
              ))
          .toList(),
    );
  }

void _addUser() {
  final userName = _nameController.text.trim();
  final validity = _validityController.text.trim();
  final note = _noteController.text.trim();
    String endTime;

  if (validity == 'Lifetime') {
    endTime = DateTime(9999, 12, 31).toIso8601String(); // Set a far future date for lifetime
  } else if (validity.contains('Days')) {
    int days = int.parse(validity.split(' ')[0]);
    endTime = DateTime.now().add(Duration(days: days)).toIso8601String();
  } else if (validity.contains('mins')) {
    int minutes = int.parse(validity.split(' ')[0]);
    endTime = DateTime.now().add(Duration(minutes: minutes)).toIso8601String();
  } else {
    // Default case or handle other validity types
    endTime = DateTime.now().toIso8601String(); // Just for safety
  }

  if (userName.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Name cannot be empty!')),
    );
    return;
  }

    // Ensure 'timeLeft' is assigned
  final timeLeft = validity.isEmpty ? 'Lifetime' : validity;
  final user = {
    'name': userName,
    'timeLeft': validity.isEmpty ? 'Lifetime' : validity,
    'note': note.isEmpty ? 'Active' : note,
    'endTime': endTime.isEmpty ? 'N/A' : endTime,
    'actions': '', // Provide default value for actions
    'validity': 'valid',
  };

  print("User Data before adding: $user");

  final userViewModel = Provider.of<UserViewModel>(context, listen: false);

  userViewModel.addUser(user).then((_) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User added successfully!')),
    );
    Navigator.pop(context);
  }).catchError((error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  });
}

}
