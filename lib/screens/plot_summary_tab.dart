import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kilimomkononi/models/field_data_model.dart';

class PlotSummaryTab extends StatelessWidget {
  final String userId;
  final List<String> plotIds;

  const PlotSummaryTab({required this.userId, required this.plotIds, super.key});

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
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plots.length,
          itemBuilder: (context, index) {
            final plot = plots[index];
            return Card(
              color: const Color.fromARGB(255, 3, 39, 4),
              child: ListTile(
                title: Text(plot.plotId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Crops: ${plot.crops.map((c) => c['type']).join(', ')}\nArea: ${plot.area} SQM\nN-P-K: ${plot.npk['N']}-${plot.npk['P']}-${plot.npk['K']}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          },
        );
      },
    );
  }
}