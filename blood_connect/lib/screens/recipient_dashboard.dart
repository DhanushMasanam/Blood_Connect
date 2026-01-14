import 'package:blood_connect/models/bloodgroup_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'profile_tab.dart';
import 'package:intl/intl.dart';

class RecipientDashboard extends StatefulWidget {
  @override
  _RecipientDashboardState createState() => _RecipientDashboardState();
}

class _RecipientDashboardState extends State<RecipientDashboard>
    with SingleTickerProviderStateMixin {
  String? _selectedBloodGroup;
  final TextEditingController _locationController = TextEditingController();
  User? _currentUser = FirebaseAuth.instance.currentUser;

  bool _isSubmitting = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _saveFcmToken();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() {
        _currentUser = user;
      });
    });

    _cleanupExpiredRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveFcmToken() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('tokens')
            .doc(token)
            .set({'token': token, 'createdAt': FieldValue.serverTimestamp()});
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('tokens')
            .doc(newToken)
            .set({'token': newToken, 'createdAt': FieldValue.serverTimestamp()});
      });
    } catch (_) {
      // silent
    }
  }

  Future<void> _notifyAdmins(
      String requestId, String bloodType, String location) async {
    final url =
        Uri.parse("https://bloodconnect-backend.onrender.com/notifyAdmins");
    try {
      await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "x-api-key": "your-strong-secret" // set from env or config
        },
        body: jsonEncode({
          "requestId": requestId,
          "bloodType": bloodType,
          "location": location,
        }),
      );
    } catch (_) {
      // non-blocking
    }
  }

  Future<void> _cleanupExpiredRequests() async {
    try {
      final now = Timestamp.now();
      final expired = await FirebaseFirestore.instance
          .collection('requests')
          .where('expiresAt', isLessThanOrEqualTo: now)
          .get();

      for (var doc in expired.docs) {
        await doc.reference.delete();
      }
    } catch (_) {
      // best-effort cleanup
    }
  }

  Future<void> _submitRequest() async {
    final now = DateTime.now();
    final expiryHours = 48;
    final expiryTime =
        Timestamp.fromDate(now.add(Duration(hours: expiryHours)));

    if (_isSubmitting) return;
    _isSubmitting = true;

    final user = _currentUser;
    if (user == null) {
      _isSubmitting = false;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Not Signed In"),
          content: const Text("Please log in again to submit a request."),
          actions: [
            ElevatedButton(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return;
    }

    final bloodType = _selectedBloodGroup ?? "";
    final location = _locationController.text.trim();

    if (bloodType.isEmpty || location.isEmpty) {
      _isSubmitting = false;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Missing Fields"),
          content: const Text("Please select a blood type and enter location."),
          actions: [
            ElevatedButton(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final recipientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final recipientData = recipientDoc.data() ?? {};
      final recipientName = (recipientData['name'] ?? 'Unknown').toString();

      final docRef =
          await FirebaseFirestore.instance.collection('requests').add({
        'recipientId': user.uid,
        'recipientName': recipientName,
        'bloodType': bloodType,
        'location': location,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiryTime,
      });

      await _notifyAdmins(docRef.id, bloodType, location);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Request Sent"),
          content: const Text("Your blood request has been sent successfully!"),
          actions: [
            ElevatedButton(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );

      _selectedBloodGroup = null;
      _locationController.clear();
      setState(() {});
    } catch (e) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Error"),
          content: const Text("Failed to submit request. Please try again."),
          actions: [
            ElevatedButton(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    } finally {
      _isSubmitting = false;
    }
  }

  Future<void> _deleteRequest(String requestId) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Request"),
        content: const Text("Are you sure you want to delete this request?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(requestId)
            .delete();

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Deleted"),
            content: const Text("Request deleted successfully."),
            actions: [
              ElevatedButton(
                child: const Text("OK"),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      } catch (e) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Failed"),
            content: const Text("Unable to delete request. Please try again."),
            actions: [
              ElevatedButton(
                child: const Text("OK"),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildPastRequests(User user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('recipientId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading requests."));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text("No past requests found."),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final bloodType = (data['bloodType'] ?? 'Unknown').toString();
            final location = (data['location'] ?? 'Unknown').toString();
            final status = (data['status'] ?? 'pending').toString();

            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final formattedDate = createdAt != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
                : "Unknown date";

            Color statusColor;
            switch (status) {
              case "pending":
                statusColor = Colors.orange;
                break;
              case "approved":
                statusColor = Colors.green;
                break;
              case "rejected":
                statusColor = Colors.red;
                break;
              default:
                statusColor = Colors.grey;
            }

            return Card(
              child: ListTile(
                leading: const Icon(Icons.bloodtype, color: Colors.red),
                title: Text("Blood Type: $bloodType"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Location: $location"),
                    Text("Status: $status", style: TextStyle(color: statusColor)),
                    Text("Created: $formattedDate"),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: "Delete request",
                  onPressed: () => _deleteRequest(docs[index].id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final bool? confirmLogout = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            child: const Text("Logout"),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recipient Dashboard"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh requests",
            onPressed: () {
              _cleanupExpiredRequests();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
            tooltip: "Logout",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Dashboard"),
            Tab(text: "Profile"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                "Request Blood",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              BloodGroupDropdown(
                selected: _selectedBloodGroup,
                onChanged: (value) {
                  setState(() {
                    _selectedBloodGroup = value;
                  });
                },
                label: "Needed Blood Group",
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: "Location",
                  prefixIcon:
                      const Icon(Icons.location_on, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle, color: Colors.white),
                label: const Text("Create New Request"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Confirm New Request"),
                      content: const Text(
                          "Do you want to create a new blood request?"),
                      actions: [
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () => Navigator.pop(ctx, false),
                        ),
                        ElevatedButton(
                          child: const Text("Yes, Create"),
                          onPressed: () => Navigator.pop(ctx, true),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _submitRequest();
                  }
                },
              ),
              const SizedBox(height: 30),
              const Text(
                "My Requests",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (user == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      "Please log in to view your requests.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                _buildPastRequests(user),
            ],
          ),
          ProfileTab(),
        ],
      ),
    );
  }
}