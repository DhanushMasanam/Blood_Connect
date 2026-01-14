import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DonorHistoryScreen extends StatelessWidget {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  DonorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Donor History"),
          backgroundColor: Colors.red,
        ),
        body: const Center(
          child: Text("Please log in to view your donor history"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Donor History"),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("donorHistory")
            .where("donorId", isEqualTo: _currentUser.uid)
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading donor history"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No donor history found"));
          }

          final history = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = history[index].data() as Map<String, dynamic>;
              final action = data['action'] ?? 'Unknown';
              final bloodType = data['bloodType'] ?? 'Unknown';
              final location = data['location'] ?? 'Unknown';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              final formatted = timestamp != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp)
                  : 'Unknown';

              return Card(
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.volunteer_activism,
                      color: Colors.blue),
                  title: Text(action),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Blood Type: $bloodType"),
                      Text("Location: $location"),
                      Text("Date: $formatted"),
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