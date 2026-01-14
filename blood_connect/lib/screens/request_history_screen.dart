import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RequestHistoryScreen extends StatelessWidget {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  RequestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
            title: const Text("Request History"), backgroundColor: Colors.red),
        body: const Center(child: Text("Please log in to view your requests")),
      );
    }

    return Scaffold(
      appBar:
          AppBar(title: const Text("Request History"), backgroundColor: Colors.red),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("requests")
            .where("recipientId", isEqualTo: _currentUser.uid)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading requests"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No requests found"));
          }

          final requests = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;
              final bloodType = data['bloodType'] ?? "N/A";
              final location = data['location'] ?? "N/A";
              final status = data['status'] ?? "pending";
              final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

              Color statusColor;
              switch (status) {
                case "approved":
                  statusColor = Colors.green;
                  break;
                case "rejected":
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.orange;
              }

              final formatted = timestamp != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp)
                  : null;

              return Card(
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.bloodtype, color: Colors.red),
                  title: Text("Blood Type: $bloodType"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Location: $location"),
                      Text("Status: $status",
                          style: TextStyle(color: statusColor)),
                      if (formatted != null)
                        Text("Requested on: $formatted",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
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