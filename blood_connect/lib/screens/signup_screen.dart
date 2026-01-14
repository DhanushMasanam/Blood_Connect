import 'package:blood_connect/models/constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedBloodGroup;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = userRoles.first;

  Future<void> _saveUserData(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _selectedRole,
      'bloodType': _selectedRole == 'Donor' ? _selectedBloodGroup : null,
      'createdAt': FieldValue.serverTimestamp(),
      'isAvailable': _selectedRole == 'Donor' ? true : null,
    }, SetOptions(merge: true));
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _saveUserData(userCredential.user!);

      if (_selectedRole == 'Donor') {
        Navigator.pushReplacementNamed(context, '/donorDashboard');
      } else if (_selectedRole == 'Recipient') {
        Navigator.pushReplacementNamed(context, '/recipientDashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/adminDashboard');
      }
    } on FirebaseAuthException catch (e) {
      String message = "Signup failed.";
      switch (e.code) {
        case 'email-already-in-use':
          message = "Email already in use.";
          break;
        case 'invalid-email':
          message = "Invalid email format.";
          break;
        case 'weak-password':
          message = "Password is too weak.";
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BloodConnect - Signup")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Email is required";
                    }
                    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!regex.hasMatch(value.trim())) {
                      return "Invalid email format";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Password is required";
                    }
                    if (value.trim().length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: userRoles
                      .map((role) =>
                          DropdownMenuItem(value: role, child: Text(role)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedRole = value!),
                  decoration: const InputDecoration(labelText: "Select Role"),
                ),
                if (_selectedRole == 'Donor')
                  DropdownButtonFormField<String>(
                    value: _selectedBloodGroup,
                    items: bloodGroups.map((group) {
                      return DropdownMenuItem(
                        value: group,
                        child: Text(group),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() {
                      _selectedBloodGroup = value;
                    }),
                    validator: (value) {
                      if (_selectedRole == 'Donor' &&
                          (value == null || value.isEmpty)) {
                        return "Please select a blood group";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: "Select Blood Group",
                      prefixIcon: const Icon(Icons.bloodtype, color: Colors.red),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signup,
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}