import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecipientHistoryTab extends StatelessWidget {
  const RecipientHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading recipient history"));
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return const Center(child: Text("No recipient history found."));
        }

        return ListView.separated(
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            final name = data['recipientName'] ?? 'Unknown';
            final bloodType = data['bloodType'] ?? 'Unknown';
            final location = data['location'] ?? 'Unknown';
            final status = data['status'] ?? 'pending';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

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

            final formatted = createdAt != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
                : 'Unknown';

            return Card(
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: Text("Recipient: $name"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Blood Type: $bloodType"),
                    Text("Location: $location"),
                    Text("Status: $status", style: TextStyle(color: statusColor)),
                    Text("Date: $formatted"),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}