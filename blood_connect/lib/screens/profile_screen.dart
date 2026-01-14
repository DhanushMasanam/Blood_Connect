import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blood_connect/models/constants.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _userData;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _selectedBloodGroup;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(_currentUser.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data();
          _nameController.text = _userData?['name'] ?? '';
          _selectedBloodGroup = _userData?['bloodType'];
          _locationController.text = _userData?['location'] ?? '';
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_currentUser == null) return;

    if (_nameController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(_currentUser.uid)
          .update({
        'name': _nameController.text.trim(),
        'bloodType': _selectedBloodGroup,
        'location': _locationController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), backgroundColor: Colors.red),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "Name",
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedBloodGroup,
            items: bloodGroups.map((group) {
              return DropdownMenuItem(
                value: group,
                child: Text(group),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedBloodGroup = value),
            decoration: const InputDecoration(
              labelText: "Blood Group",
              prefixIcon: Icon(Icons.bloodtype),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: "Location",
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Save Changes"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _updateProfile,
          ),
        ],
      ),
    );
  }
}