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
  final TextEditingController _endDateController = TextEditingController();

  void setValidity(String validity) {
    setState(() {
      _validityController.text = validity;
      final currentDate = DateTime.now();

      if (validity == '30 Days') {
        _endDateController.text =
            DateFormat('MM/dd/yyyy').format(currentDate.add(Duration(days: 30)));
      } else if (validity == '1 Year') {
        _endDateController.text = DateFormat('MM/dd/yyyy').format(
            DateTime(currentDate.year + 1, currentDate.month, currentDate.day));
      } else if (validity == 'Lifetime') {
        _endDateController.text = 'Lifetime';
      } else if (validity == '10 mins') {
        _endDateController.text = DateFormat('MM/dd/yyyy HH:mm')
            .format(currentDate.add(Duration(minutes: 10)));
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _validityController.dispose();
    _noteController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF273562),
        title: Center(
          child: Text(
            'Add User',
            style: GoogleFonts.montserrat(
              fontSize: 30,
              color: const Color(0xFFFFA600),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
                  _endDateController, readOnly: true),
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
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ['30 Days', '1 Year', 'Lifetime', '10 mins']
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
  if (_nameController.text.trim().isEmpty ||
      _validityController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in all required fields')),
    );
    return;
  }

  final user = {
    'name': _nameController.text.trim(),
    'timeLeft': _validityController.text.isEmpty ? 'Lifetime' : _validityController.text,
    'actions': _noteController.text.isEmpty ? 'Active' : _noteController.text,
  };

  print("Adding User: $user");
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