import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsTab extends StatelessWidget {
  // ✅ Helper widget for legends
  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text("📊 Overall Analytics",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

        SizedBox(height: 20),

        // 🔹 Active Donors by Blood Type (Bar Chart)
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'Donor')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            final donors = snapshot.data!.docs;

            final Map<String, int> bloodCounts = {};
            for (var doc in donors) {
              final data = doc.data() as Map<String, dynamic>;
              final bloodType = data['bloodType'] ?? 'Unknown';
              if (data['isAvailable'] == true) {
                bloodCounts[bloodType] = (bloodCounts[bloodType] ?? 0) + 1;
              }
            }

            final barSpots = bloodCounts.entries.map((e) {
              return BarChartGroupData(
                x: bloodCounts.keys.toList().indexOf(e.key),
                barRods: [
                  BarChartRodData(toY: e.value.toDouble(), color: Colors.red)
                ],
              );
            }).toList();

            return Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bloodtype, color: Colors.red),
                        SizedBox(width: 8),
                        Text("Active Donors by Blood Type",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 200,
                      child: BarChart(
                        BarChartData(
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final bloodType =
                                      bloodCounts.keys.elementAt(value.toInt());
                                  return Text(bloodType,
                                      style: TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                          ),
                          barGroups: barSpots,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: bloodCounts.keys.map((bloodType) {
                        return _buildLegendItem(bloodType, Colors.red);
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // 🔹 Requests by Status (Pie Chart)
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('requests').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            final requests = snapshot.data!.docs;

            int pending = 0, approved = 0, rejected = 0;
            for (var doc in requests) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              if (status == 'approved') approved++;
              else if (status == 'rejected') rejected++;
              else pending++;
            }

            final sections = [
              PieChartSectionData(value: pending.toDouble(), color: Colors.orange, title: "Pending"),
              PieChartSectionData(value: approved.toDouble(), color: Colors.green, title: "Approved"),
              PieChartSectionData(value: rejected.toDouble(), color: Colors.red, title: "Rejected"),
            ];

            return Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment, color: Colors.blue),
                        SizedBox(width: 8),
                        Text("Requests by Status",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 200,
                      child: PieChart(PieChartData(sections: sections)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem("Pending", Colors.orange),
                        _buildLegendItem("Approved", Colors.green),
                        _buildLegendItem("Rejected", Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // 🔹 Requests Over Time (Line Chart)
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('requests').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            final requests = snapshot.data!.docs;

            final Map<String, int> monthlyCounts = {};
            for (var doc in requests) {
              final data = doc.data() as Map<String, dynamic>;
              final ts = data['createdAt'];
              if (ts != null) {
                final date = (ts as Timestamp).toDate();
                final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
                monthlyCounts[key] = (monthlyCounts[key] ?? 0) + 1;
              }
            }

            final sortedKeys = monthlyCounts.keys.toList()..sort();
            final spots = <FlSpot>[];
            for (int i = 0; i < sortedKeys.length; i++) {
              spots.add(FlSpot(i.toDouble(), monthlyCounts[sortedKeys[i]]!.toDouble()));
            }

            return Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timeline, color: Colors.purple),
                        SizedBox(width: 8),
                        Text("Requests Over Time",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 200,
                      child: LineChart(
                        LineChartData(
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < sortedKeys.length) {
                                    return Text(sortedKeys[value.toInt()],
                                        style: TextStyle(fontSize: 10));
                                  }
                                  return Text("");
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem("Requests per Month", Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}