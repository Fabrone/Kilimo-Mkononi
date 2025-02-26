import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kilimomkononi/models/field_data_model.dart';

class PlotAnalyticsTab extends StatelessWidget {
  final String userId;
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
        if (snapshot.hasError) return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

        final plots = snapshot.data!.docs.map((doc) => FieldData.fromMap(doc.data() as Map<String, dynamic>)).toList();
        final avgN = plots.isEmpty ? 0 : plots.map((p) => p.npk['N']!).reduce((a, b) => a + b) / plots.length;
        final avgP = plots.isEmpty ? 0 : plots.map((p) => p.npk['P']!).reduce((a, b) => a + b) / plots.length;
        final avgK = plots.isEmpty ? 0 : plots.map((p) => p.npk['K']!).reduce((a, b) => a + b) / plots.length;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Analytics', style: TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 16),
              Text('Average N-P-K (kg/ha): $avgN - $avgP - $avgK', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              const Text('Recent Interventions:', style: TextStyle(color: Colors.white)),
              ...plots.expand((p) => p.interventions.map((i) => Text(
                    '${p.plotId}: ${i['type']} (${i['quantity']} ${i['unit']}) on ${(i['date'] as Timestamp).toDate().toString().substring(0, 10)}',
                    style: const TextStyle(color: Colors.white70),
                  ))).take(5),
            ],
          ),
        );
      },
    );
  }
}