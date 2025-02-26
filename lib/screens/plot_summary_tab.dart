import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kilimomkononi/models/field_data_model.dart';

class PlotSummaryTab extends StatefulWidget {
  final String userId;
  final List<String> plotIds;

  const PlotSummaryTab({required this.userId, required this.plotIds, super.key});

  @override
  State<PlotSummaryTab> createState() => _PlotSummaryTabState();
}

class _PlotSummaryTabState extends State<PlotSummaryTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fielddata')
          .where('userId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(fontSize: 32),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final plots = snapshot.data!.docs.map((doc) => FieldData.fromMap(doc.data() as Map<String, dynamic>)).toList();

        if (plots.isEmpty) {
          return Center(
            child: Text(
              'No plot data available.',
              style: const TextStyle(fontSize: 32),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plots.length,
          itemBuilder: (context, index) {
            final plot = plots[index];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          plot.plotId,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 3, 39, 4),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editPlot(context, plot),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePlot(context, plot),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crops: ${plot.crops.map((c) => c['type']).join(', ')}',
                      style: const TextStyle(fontSize: 32, color: Colors.black87),
                    ),
                    Text(
                      'Area: ${plot.area} SQM',
                      style: const TextStyle(fontSize: 32, color: Colors.black87),
                    ),
                    Text(
                      'N-P-K: ${plot.npk['N']}-${plot.npk['P']}-${plot.npk['K']}',
                      style: const TextStyle(fontSize: 32, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editPlot(BuildContext context, FieldData plot) {
    Navigator.pushNamed(
      context,
      '/plot_input',
      arguments: {
        'userId': widget.userId,
        'plotId': plot.plotId,
        'existingData': plot,
      },
    );
  }

  void _deletePlot(BuildContext context, FieldData plot) async {
    // Capture ScaffoldMessengerState before async operations
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${plot.plotId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('fielddata')
            .doc('${widget.userId}_${plot.plotId}')
            .delete();
        if (mounted) { // Still good to keep mounted for safety
          messenger.showSnackBar(
            SnackBar(content: Text('${plot.plotId} deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error deleting plot: $e')),
          );
        }
      }
    }
  }
}