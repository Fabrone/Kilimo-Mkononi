import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kilimomkononi/models/field_data_model.dart';

class PlotAnalyticsTab extends StatelessWidget {
  final String userId; // Matches Firebase Auth UID from HomePage
  final List<String> plotIds;

  const PlotAnalyticsTab({required this.userId, required this.plotIds, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fielddata')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final plots = snapshot.data!.docs.map((doc) => FieldData.fromMap(doc.data() as Map<String, dynamic>)).toList();

        if (plots.isEmpty) {
          return const Center(
            child: Text(
              'No analytics data available yet. Add some field data to see insights!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        }

        final avgN = plots.isEmpty ? 0 : plots.map((p) => p.npk['N']!).reduce((a, b) => a + b) / plots.length;
        final avgP = plots.isEmpty ? 0 : plots.map((p) => p.npk['P']!).reduce((a, b) => a + b) / plots.length;
        final avgK = plots.isEmpty ? 0 : plots.map((p) => p.npk['K']!).reduce((a, b) => a + b) / plots.length;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 3, 39, 4), // Match app theme
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Average N-P-K (kg/ha): ${avgN.toStringAsFixed(1)} - ${avgP.toStringAsFixed(1)} - ${avgK.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recent Interventions:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 8),
              plots.isNotEmpty && plots.any((p) => p.interventions.isNotEmpty)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: plots
                          .expand((p) => p.interventions.map((i) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '${p.plotId}: ${i['type']} (${i['quantity']} ${i['unit']}) on ${(i['date'] as Timestamp).toDate().toString().substring(0, 10)}',
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                ),
                              )))
                          .take(5)
                          .toList(),
                    )
                  : const Text(
                      'No recent interventions recorded.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
            ],
          ),
        );
      },
    );
  }
}