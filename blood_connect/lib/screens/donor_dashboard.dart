import 'package:blood_connect/services/request_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_tab.dart';
import 'package:intl/intl.dart';
import 'package:blood_connect/models/constants.dart' as Constants;

class DonorDashboard extends StatefulWidget {
  @override
  _DonorDashboardState createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard>
    with SingleTickerProviderStateMixin {
  // ignore: unused_field
  User? _currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  // Persisted UI state (fixes filters/search resetting)
  String filterBloodType = 'All';
  String filterStatus = 'All';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() {
        _currentUser = user;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------------- Active Requests ----------------
  Widget _buildActiveRequests() {
    return _buildRequestsSection(showPast: false);
  }

  // ---------------- Past Requests ----------------
  Widget _buildPastRequests() {
    return _buildRequestsSection(showPast: true);
  }

  // ---------------- Shared Requests Section ----------------
  Widget _buildRequestsSection({required bool showPast}) {
    return Column(
      children: [
        // Filters row
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filterBloodType,
                  items: ['All', ...Constants.bloodGroups]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => filterBloodType = val!),
                  decoration: const InputDecoration(
                    labelText: "Blood Type",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filterStatus,
                  items: ['All', ...Constants.requestStatuses]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => filterStatus = val!),
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
            controller: _searchCtrl,
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

              final query = _searchCtrl.text.trim().toLowerCase();
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final bloodType = (data['bloodType'] ?? '').toString();
                final status = (data['status'] ?? '').toString().toLowerCase();
                final recipientName =
                    (data['recipientName'] ?? '').toString().toLowerCase();
                final location =
                    (data['location'] ?? '').toString().toLowerCase();

                final bloodMatch =
                    filterBloodType == 'All' || bloodType == filterBloodType;
                final statusMatch = filterStatus == 'All' ||
                    status == filterStatus.toLowerCase();
                final searchMatch = query.isEmpty ||
                    recipientName.contains(query) ||
                    location.contains(query);

                // Separate active vs past by status
                final isPast = status != "pending";
                return bloodMatch &&
                    statusMatch &&
                    searchMatch &&
                    (showPast ? isPast : !isPast);
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
                  final recipientName =
                      data['recipientName']?.toString() ?? 'Unknown';
                  final bloodType = data['bloodType']?.toString() ?? 'Unknown';
                  final location = data['location']?.toString() ?? 'Unknown';
                  final status =
                      (data['status']?.toString() ?? 'pending').toLowerCase();
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
                    case "approved":
                      statusColor = Colors.green;
                      break;
                    case "rejected":
                      statusColor = Colors.red;
                      break;
                    case "fulfilled":
                      statusColor = Colors.blue;
                      break;
                    case "expired":
                      statusColor = Colors.grey;
                      break;
                    default:
                      statusColor = Colors.orange; // pending
                  }

                  final isUrgent = (data['urgent'] == true) ||
                      (expiresAt != null &&
                          expiresAt.isBefore(
                              DateTime.now().add(const Duration(hours: 4))));

                  return Card(
                    color: isUrgent ? Colors.red[50] : null,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Text(
                          bloodType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      title: Text("Recipient: $recipientName"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Blood Type: $bloodType"),
                          Text("Location: $location"),
                          Text("Status: ${status.toLowerCase()}",
                              style: TextStyle(color: statusColor)),
                          Text("Requested: $requestedStr"),
                          Text("Expires: $expiresStr"),
                        ],
                      ),
                      trailing: status == "pending"
                          ? ElevatedButton(
                              child: const Text("Respond"),
                              onPressed: () async {
                                final bool? confirm = await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Confirm Response"),
                                    content: const Text(
                                        "Do you want to respond to this request?"),
                                    actions: [
                                      TextButton(
                                        child: const Text("Cancel"),
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                      ),
                                      ElevatedButton(
                                        child: const Text("Yes, Respond"),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await RequestService.approveRequest(doc.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "You responded to $recipientName"),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "Failed to approve: $e"),
                                      ),
                                    );
                                  }
                                }
                              },
                            )
                          : status == "approved"
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  child: const Text("Mark Fulfilled"),
                                  onPressed: () async {
                                    final bool? confirm = await showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title:
                                            const Text("Confirm Fulfillment"),
                                        content: const Text(
                                            "Have you donated and want to mark this request as fulfilled?"),
                                        actions: [
                                          TextButton(
                                            child: const Text("Cancel"),
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                          ),
                                          ElevatedButton(
                                            child:
                                                const Text("Yes, Fulfilled"),
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        await RequestService.fulfillRequest(
                                            doc.id);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                "Marked fulfilled for $recipientName"),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                "Failed to fulfill: $e"),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                )
                              : null, // Past requests won't show actions
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Donor Dashboard"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(onPressed: (){
            setState(() {
              
            });
          }, icon: const Icon(Icons.refresh)),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Active Requests"),
            Tab(text: "Past Requests"),
            Tab(text: "Profile"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveRequests(),
          _buildPastRequests(),
          ProfileTab(),
        ],
      ),
    );
  }
}