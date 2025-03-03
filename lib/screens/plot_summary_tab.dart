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
    final prefixedPlotIds = widget.plotIds.map((id) => '${widget.userId}_$id').toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 3, 39, 4),
        title: const Text(
          'Plot Summary',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fielddata')
            .where('userId', isEqualTo: widget.userId)
            .where(FieldPath.documentId, whereIn: prefixedPlotIds)
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
          if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final plots = snapshot.data!.docs.map((doc) => FieldData.fromMap(doc.data() as Map<String, dynamic>)).toList();

          if (plots.isEmpty) {
            return const Center(
              child: Text(
                'No plot data available.',
                style: TextStyle(fontSize: 16, color: Colors.black),
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
                              fontSize: 18,
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
                      _buildFieldRow('Crops', plot.crops.isNotEmpty
                          ? plot.crops.map((c) => '${c['type']} (${c['stage']})').join(', ')
                          : 'None'),
                      _buildFieldRow('Area', plot.area != null ? '${plot.area} SQM' : 'None'),
                      _buildFieldRow('Nitrogen (N)', plot.npk['N'] != null ? '${plot.npk['N']}' : 'None'),
                      _buildFieldRow('Phosphorus (P)', plot.npk['P'] != null ? '${plot.npk['P']}' : 'None'),
                      _buildFieldRow('Potassium (K)', plot.npk['K'] != null ? '${plot.npk['K']}' : 'None'),
                      _buildFieldRow('Micro-Nutrients', plot.microNutrients.isNotEmpty ? plot.microNutrients.join(', ') : 'None'),
                      _buildFieldRow('Interventions', plot.interventions.isNotEmpty
                          ? plot.interventions.map((i) => '${i['type']} (${i['quantity']} ${i['unit']})').join(', ')
                          : 'None'),
                      _buildFieldRow('Reminders', plot.reminders.isNotEmpty
                          ? plot.reminders.map((r) => '${r['activity']} (${r['date'].toDate().toString().substring(0, 10)})').join(', ')
                          : 'None'),
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

  Widget _buildFieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _editPlot(BuildContext context, FieldData plot) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final List<TextEditingController> cropControllers = plot.crops.map((c) => TextEditingController(text: c['type'])).toList();
    final List<TextEditingController> stageControllers = plot.crops.map((c) => TextEditingController(text: c['stage'])).toList();
    final TextEditingController areaController = TextEditingController(text: plot.area?.toString());
    final TextEditingController nitrogenController = TextEditingController(text: plot.npk['N']?.toString());
    final TextEditingController phosphorusController = TextEditingController(text: plot.npk['P']?.toString());
    final TextEditingController potassiumController = TextEditingController(text: plot.npk['K']?.toString());
    final List<TextEditingController> microNutrientControllers =
        plot.microNutrients.map((m) => TextEditingController(text: m)).toList()..add(TextEditingController());

    List<Map<String, String>> editedCrops = List.from(plot.crops);
    List<String> editedMicroNutrients = List.from(plot.microNutrients);
    List<Map<String, dynamic>> editedInterventions = List.from(plot.interventions);
    List<Map<String, dynamic>> editedReminders = List.from(plot.reminders);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit ${plot.plotId}'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...cropControllers.asMap().entries.map((entry) {
                  int idx = entry.key;
                  return Column(
                    children: [
                      TextField(
                        controller: cropControllers[idx],
                        decoration: InputDecoration(labelText: 'Crop Type ${idx + 1}'),
                      ),
                      TextField(
                        controller: stageControllers[idx],
                        decoration: InputDecoration(labelText: 'Crop Stage ${idx + 1}'),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
                if (plot.plotId.contains('Intercrop'))
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        cropControllers.add(TextEditingController());
                        stageControllers.add(TextEditingController());
                        editedCrops.add({'type': '', 'stage': ''});
                      });
                    },
                    child: const Text('+ Additional Crop'),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: areaController,
                  decoration: const InputDecoration(labelText: 'Area (SQM)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nitrogenController,
                  decoration: const InputDecoration(labelText: 'Nitrogen (N)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: phosphorusController,
                  decoration: const InputDecoration(labelText: 'Phosphorus (P)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: potassiumController,
                  decoration: const InputDecoration(labelText: 'Potassium (K)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Column(
                  children: microNutrientControllers.map((controller) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(labelText: 'Micro-Nutrient'),
                      onSubmitted: (value) {
                        if (value.isNotEmpty && !editedMicroNutrients.contains(value)) {
                          setState(() => editedMicroNutrients.add(value));
                        }
                      },
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() => microNutrientControllers.add(TextEditingController())),
                  child: const Text('Add Another Micro-Nutrient'),
                ),
                Wrap(
                  spacing: 8,
                  children: editedMicroNutrients.map((m) => Chip(
                    label: Text(m),
                    onDeleted: () => setState(() => editedMicroNutrients.remove(m)),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              editedMicroNutrients = microNutrientControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
              editedCrops = cropControllers.asMap().entries.map((entry) {
                int idx = entry.key;
                return {
                  'type': cropControllers[idx].text,
                  'stage': stageControllers[idx].text,
                };
              }).where((c) => c['type']!.isNotEmpty).toList();
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final updatedFieldData = FieldData(
        userId: widget.userId,
        plotId: plot.plotId,
        crops: editedCrops,
        area: areaController.text.isNotEmpty ? double.parse(areaController.text) : null,
        npk: {
          'N': nitrogenController.text.isNotEmpty ? double.parse(nitrogenController.text) : null,
          'P': phosphorusController.text.isNotEmpty ? double.parse(phosphorusController.text) : null,
          'K': potassiumController.text.isNotEmpty ? double.parse(potassiumController.text) : null,
        },
        microNutrients: editedMicroNutrients,
        interventions: editedInterventions,
        reminders: editedReminders,
        timestamp: Timestamp.now(),
      );

      try {
        await FirebaseFirestore.instance
            .collection('fielddata')
            .doc('${widget.userId}_${plot.plotId}')
            .set(updatedFieldData.toMap());
        if (mounted) {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Plot updated successfully')));
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error updating plot: $e')));
        }
      }
    }
  }

  Future<void> _deletePlot(BuildContext context, FieldData plot) async {
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

    if (confirm == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('fielddata')
            .doc('${widget.userId}_${plot.plotId}')
            .delete();
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text('${plot.plotId} deleted successfully')));
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text('Error deleting plot: $e')));
        }
      }
    }
  }
}