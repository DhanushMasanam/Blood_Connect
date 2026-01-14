import 'package:blood_connect/models/bloodgroup_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileTab extends StatefulWidget {
  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String? _selectedBloodGroup;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_currentUser == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['name'] ?? '';
      _selectedBloodGroup = data['bloodType'];
      _locationController.text = data['location'] ?? '';
      _isAvailable = data['isAvailable'] ?? false;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateProfile() async {
    if (_currentUser == null) return;

    if (_nameController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .update({
        'name': _nameController.text.trim(),
        'bloodType': _selectedBloodGroup,
        'location': _locationController.text.trim(),
        'isAvailable': _isAvailable,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (_currentUser == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _currentUser.email!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: "Name"),
        ),
        const SizedBox(height: 12),
        BloodGroupDropdown(
          selected: _selectedBloodGroup,
          onChanged: (value) {
            setState(() {
              _selectedBloodGroup = value;
            });
          },
          label: "Your Blood Group",
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(labelText: "Location"),
        ),
        SwitchListTile(
          title: const Text("Available for donation"),
          value: _isAvailable,
          onChanged: (val) => setState(() => _isAvailable = val),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _updateProfile,
          child: const Text("Save Changes"),
        ),
        TextButton(
          onPressed: _resetPassword,
          child: const Text("Reset Password"),
        ),
      ],
    );
  }
}