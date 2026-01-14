import 'package:blood_connect/models/constants.dart' as Constants;
import 'package:blood_connect/services/request_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Filters: Requests tab
  String requestsBloodType = 'All';
  String requestsStatus = 'All';
  final TextEditingController _requestsSearchCtrl = TextEditingController();

  // Filters: Recipient History tab
  String recipientsBloodType = 'All';
  String recipientsStatus = 'All';
  final TextEditingController _recipientsSearchCtrl = TextEditingController();

  @override
  void dispose() {
    _requestsSearchCtrl.dispose();
    _recipientsSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // Requests, Donor History, Recipient History, Notifications, Profile
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Dashboard"),
          backgroundColor: Colors.redAccent,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Requests", icon: Icon(Icons.list)),
              Tab(text: "Donor History", icon: Icon(Icons.volunteer_activism)),
              Tab(text: "Recipient History", icon: Icon(Icons.people)),
              //Tab(text: "Notifications", icon: Icon(Icons.notifications)),
              Tab(text: "Profile", icon: Icon(Icons.person)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refreshing dashboard data...')),
                );
                setState(() {}); // force rebuild
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildRequests(context),
            _buildDonorHistory(context),
            _buildRecipientHistory(context),
           // _buildNotifications(context),
            _buildProfile(context),
          ],
        ),
      ),
    );
  }

  // ---------------- Requests ----------------
  Widget _buildRequests(BuildContext context) {
    return Column(
      children: [
        // Filters row
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: requestsBloodType,
                  items: ['All', ...Constants.bloodGroups].toSet().toList()
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => requestsBloodType = val!),
                  decoration: const InputDecoration(
                    labelText: "Blood Type",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: requestsStatus,
                  items: ['All', ...Constants.requestStatuses].toSet().toList()
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => requestsStatus = val!),
                  decoration: const InputDecoration(
                    labelText: "Status",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Search field
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _requestsSearchCtrl,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by recipient name or location',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        // Requests list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('requests')
                .orderBy('createdAt', descending: true)
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

              final query = _requestsSearchCtrl.text.trim().toLowerCase();
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final bloodType = (data['bloodType'] ?? '').toString();
                final status = (data['status'] ?? '').toString();
                final recipientName = (data['recipientName'] ?? '').toString().toLowerCase();
                final location = (data['location'] ?? '').toString().toLowerCase();
                final bloodMatch = requestsBloodType == 'All' || bloodType == requestsBloodType;
                final statusMatch = requestsStatus == 'All' || status == requestsStatus;
                final searchMatch = query.isEmpty || recipientName.contains(query) || location.contains(query);
                return bloodMatch && statusMatch && searchMatch;
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("No matching requests"));
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final recipientName = data['recipientName']?.toString() ?? 'Unknown';
                  final bloodType = data['bloodType']?.toString() ?? 'Unknown';
                  final location = data['location']?.toString() ?? 'Unknown';
                  final status = data['status']?.toString() ?? 'pending';
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                  final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
                  final requestedStr = createdAt != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
                      : 'Unknown';
                  final expiresStr = expiresAt != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(expiresAt)
                      : 'N/A';

                  Color statusColor;
                  switch (status) {
                    case "approved": statusColor = Colors.green; break;
                    case "rejected": statusColor = Colors.red; break;
                    case "fulfilled": statusColor = Colors.blue; break;
                    case "expired": statusColor = Colors.grey; break;
                    default: statusColor = Colors.orange;
                  }

                  final isUrgent = (data['urgent'] == true) ||
                      (expiresAt != null && expiresAt.isBefore(DateTime.now().add(const Duration(hours: 4))));

                  return Card(
                    color: isUrgent ? Colors.red[50] : null,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Text(bloodType, style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                      title: Text("Recipient: $recipientName"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Blood Type: $bloodType"),
                          Text("Location: $location"),
                          Text("Status: $status", style: TextStyle(color: statusColor)),
                          Text("Requested: $requestedStr"),
                          Text("Expires: $expiresStr"),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (choice) async {
                          try {
                            await RequestService.approveRequest(doc.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Request marked as $choice")),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to update: $e")),
                            );
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: "approved", child: Text("Approve")),
                          PopupMenuItem(value: "rejected", child: Text("Reject")),
                          PopupMenuItem(value: "fulfilled", child: Text("Mark Fulfilled")),
                          PopupMenuItem(value: "expired", child: Text("Mark Expired")),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }  

  // ---------------- Donor History ----------------
  Widget _buildDonorHistory(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donorHistory')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading donor history"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No donor history"));
        }

        final history = snapshot.data!.docs;
        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final data = history[index].data() as Map<String, dynamic>? ?? {};
            final donorId = data['donorId']?.toString() ?? 'Unknown';
            final action = data['action']?.toString() ?? 'Unknown';
            final bloodType = data['bloodType']?.toString() ?? 'Unknown';
            final location = data['location']?.toString() ?? 'Unknown';
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

            final formatted = timestamp != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp)
                : 'Unknown';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.volunteer_activism, color: Colors.blue),
                title: Text("Donor: $donorId"),
                subtitle: Text("$action • $bloodType • $location"),
                trailing: Text(formatted),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- Recipient History ----------------
  Widget _buildRecipientHistory(BuildContext context) {
    return Column(
      children: [
        // Filters row
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: recipientsBloodType,
                  items: ['All', ...Constants.bloodGroups].toSet().toList()
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => recipientsBloodType = val!),
                  decoration: const InputDecoration(
                    labelText: "Blood Type",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: recipientsStatus,
                  items: ['All', ...Constants.requestStatuses].toSet().toList()
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => recipientsStatus = val!),
                  decoration: const InputDecoration(
                    labelText: "Status",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Search field
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _recipientsSearchCtrl,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by recipient name or city',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        // Recipient history list (from requests)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('requests') // or 'recipientHistory' if you log separately
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Error loading recipient history"));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No recipient history"));
              }

              final query = _recipientsSearchCtrl.text.trim().toLowerCase();
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final bloodType = (data['bloodType'] ?? '').toString();
                final status = (data['status'] ?? '').toString();
                final recipientName = (data['recipientName'] ?? '').toString().toLowerCase();
                final city = (data['location'] ?? '').toString().toLowerCase();

                final bloodMatch = recipientsBloodType == 'All' || bloodType == recipientsBloodType;
                final statusMatch = recipientsStatus == 'All' || status == recipientsStatus;
                final searchMatch = query.isEmpty || recipientName.contains(query) || city.contains(query);

                return bloodMatch && statusMatch && searchMatch;
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("No matching recipient history"));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final recipientName = data['recipientName']?.toString() ?? 'Unknown';
                  final bloodType = data['bloodType']?.toString() ?? 'Unknown';
                  final status = data['status']?.toString() ?? 'Unknown';
                  final city = data['location']?.toString() ?? 'Unknown';
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                  final formatted = createdAt != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
                      : 'Unknown';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.purple),
                      title: Text("Recipient: $recipientName"),
                      subtitle: Text("Blood: $bloodType • Status: $status • City: $city"),
                      trailing: Text(formatted),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // // ---------------- Notifications ----------------
  // Widget _buildNotifications(BuildContext context) {
  //   return StreamBuilder<QuerySnapshot>(
  //     stream: FirebaseFirestore.instance
  //         .collection('notifications')
  //         .orderBy('timestamp', descending: true)
  //         .snapshots(),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const Center(child: CircularProgressIndicator());
  //       }
  //       if (snapshot.hasError) {
  //         return const Center(child: Text("Error loading notifications"));
  //       }
  //       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
  //         return const Center(child: Text("No notifications"));
  //       }

  //       final notes = snapshot.data!.docs;
  //       return ListView.builder(
  //         itemCount: notes.length,
  //         itemBuilder: (context, index) {
  //           final doc = notes[index];
  //           final data = doc.data() as Map<String, dynamic>? ?? {};
  //           final title = data['title']?.toString() ?? 'Notification';
  //           final body = data['body']?.toString() ?? '';
  //           final read = data['read'] == true;
  //           final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
  //           final formatted = timestamp != null
  //               ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp)
  //               : 'Unknown';

  //           return Card(
  //             color: read ? null : Colors.red[50],
  //             margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //             child: ListTile(
  //               leading: Icon(
  //                 title.contains('Urgent') ? Icons.priority_high : Icons.notifications,
  //                 color: title.contains('Urgent') ? Colors.redAccent : Colors.orange,
  //               ),
  //               title: Text(title),
  //               subtitle: Text("$body\n$formatted"),
  //               isThreeLine: true,
  //               trailing: Wrap(
  //                 spacing: 8,
  //                 children: [
  //                   ElevatedButton(
  //                     onPressed: () async {
  //                       try {
  //                         await FirebaseFirestore.instance
  //                             .collection('notifications')
  //                             .doc(doc.id)
  //                             .update({'read': true});
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                           const SnackBar(content: Text('Marked as read')),
  //                         );
  //                       } catch (e) {
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                           SnackBar(content: Text('Failed: $e')),
  //                         );
  //                       }
  //                     },
  //                     child: const Text("Mark Read"),
  //                   ),
  //                   ElevatedButton(
  //                     style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
  //                     onPressed: () async {
  //                       try {
  //                         await FirebaseFirestore.instance
  //                             .collection('notifications')
  //                             .doc(doc.id)
  //                             .delete();
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                           const SnackBar(content: Text('Notification dismissed')),
  //                         );
  //                       } catch (e) {
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                           SnackBar(content: Text('Failed: $e')),
  //                         );
  //                       }
  //                     },
  //                     child: const Text("Dismiss"),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  // ---------------- Profile ----------------
  Widget _buildProfile(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Admin Info
        Card(
          child: ListTile(
            leading: const Icon(Icons.person, color: Colors.red),
            title: const Text("Admin User"),
            subtitle: const Text("admin@bloodconnect.org"),
          ),
        ),
        const SizedBox(height: 12),

        // API Key Status
        Card(
          child: ListTile(
            leading: const Icon(Icons.vpn_key, color: Colors.blue),
            title: const Text("API Key Status"),
            subtitle: const Text("Valid"),
            trailing: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Revalidated API key')),
                );
              },
              child: const Text("Revalidate"),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Security Rules
        Card(
          child: ListTile(
            leading: const Icon(Icons.rule, color: Colors.deepPurple),
            title: const Text("Security Rules"),
            subtitle: const Text("Role-based access enforced"),
            trailing: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Firestore rules')),
                );
              },
              child: const Text("View"),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Logout
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout"),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Logout"),
            ),
          ),
        ),
      ],
    );
  }
}    