import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.red,
      ),
      body: _currentUser == null
          ? const Center(child: Text("Please log in to view notifications"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("notifications")
                  .where("userId", isEqualTo: _currentUser.uid)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading notifications"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No notifications yet"));
                }

                final notifications = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data =
                        notifications[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? "Notification";
                    final body = data['body'] ?? "";
                    final timestamp =
                        (data['timestamp'] as Timestamp?)?.toDate();
                    final type = data['type'] as String?;

                    IconData leadingIcon;
                    switch (type) {
                      case 'system':
                        leadingIcon = Icons.notifications;
                        break;
                      case 'request_update':
                        leadingIcon = Icons.update;
                        break;
                      default:
                        leadingIcon = Icons.bloodtype;
                    }

                    final formatted =
                        timestamp != null ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp) : null;

                    return Card(
                      elevation: 3,
                      child: ListTile(
                        leading: Icon(leadingIcon, color: Colors.red),
                        title: Text(
                          title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(body),
                            if (formatted != null)
                              Text(
                                formatted,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}