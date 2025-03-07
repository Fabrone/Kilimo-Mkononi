import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kilimomkononi/models/pest_disease_model.dart';

class UserPestHistoryPage extends StatefulWidget {
  const UserPestHistoryPage({super.key});

  @override
  State<UserPestHistoryPage> createState() => _UserPestHistoryPageState();
}

class _UserPestHistoryPageState extends State<UserPestHistoryPage> {
  List<PestIntervention> _interventions = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('pestinterventiondata')
        .doc(user.uid)
        .collection('interventions')
        .where('isDeleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      _interventions = snapshot.docs.map((doc) => PestIntervention.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> _editIntervention(PestIntervention intervention) async {
    final controller = TextEditingController(text: intervention.intervention);
    final dosageController = TextEditingController(text: intervention.dosage?.toString() ?? '');
    final unitController = TextEditingController(text: intervention.unit);
    final areaController = TextEditingController(text: intervention.area?.toString() ?? '');
    bool useSQM = intervention.areaUnit == 'SQM';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Intervention'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: controller, decoration: const InputDecoration(labelText: 'Intervention Used')),
                TextField(controller: dosageController, decoration: const InputDecoration(labelText: 'Dosage Applied'), keyboardType: TextInputType.number),
                TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit')),
                TextField(controller: areaController, decoration: const InputDecoration(labelText: 'Total Area Affected'), keyboardType: TextInputType.number),
                SwitchListTile(
                  title: const Text('Use SQM'),
                  value: useSQM,
                  onChanged: (value) => setDialogState(() => useSQM = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final updatedIntervention = intervention.copyWith(
        intervention: controller.text,
        dosage: dosageController.text.isNotEmpty ? double.parse(dosageController.text) : null,
        unit: unitController.text.isNotEmpty ? unitController.text : null,
        area: areaController.text.isNotEmpty ? double.parse(areaController.text) : null,
        areaUnit: useSQM ? 'SQM' : 'Acres',
      );

      final user = FirebaseAuth.instance.currentUser!;
      try {
        await FirebaseFirestore.instance
            .collection('pestinterventiondata')
            .doc(user.uid)
            .collection('interventions')
            .doc(intervention.id)
            .set(updatedIntervention.toMap());

        await FirebaseFirestore.instance.collection('User_logs').add({
          'userId': user.uid,
          'action': 'edit',
          'collection': 'pestinterventiondata',
          'documentId': intervention.id,
          'timestamp': Timestamp.now(),
          'details': 'Updated intervention for ${intervention.pestName}',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intervention updated successfully')));
          setState(() {
            _interventions[_interventions.indexWhere((i) => i.id == intervention.id)] = updatedIntervention;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating intervention: $e')));
        }
      }
    }
  }

  Future<void> _deleteIntervention(PestIntervention intervention) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this intervention? It can be restored by an admin.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final user = FirebaseAuth.instance.currentUser!;
      try {
        await FirebaseFirestore.instance
            .collection('pestinterventiondata')
            .doc(user.uid)
            .collection('interventions')
            .doc(intervention.id)
            .update({'isDeleted': true});

        await FirebaseFirestore.instance.collection('User_logs').add({
          'userId': user.uid,
          'action': 'delete',
          'collection': 'pestinterventiondata',
          'documentId': intervention.id,
          'timestamp': Timestamp.now(),
          'details': 'Soft-deleted intervention for ${intervention.pestName}',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intervention deleted successfully')));
          setState(() {
            _interventions.removeWhere((i) => i.id == intervention.id);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting intervention: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pest Management History', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 3, 39, 4),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(16.0),
        child: _interventions.isEmpty
            ? const Center(child: Text('No pest management history available.'))
            : ListView.builder(
                itemCount: _interventions.length,
                itemBuilder: (context, index) {
                  final intervention = _interventions[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pest: ${intervention.pestName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Crop: ${intervention.cropType}'),
                          Text('Stage: ${intervention.cropStage}'),
                          Text('Intervention: ${intervention.intervention.isNotEmpty ? intervention.intervention : "None"}'),
                          Text('Dosage: ${intervention.dosage ?? "N/A"} ${intervention.unit ?? ""}'),
                          Text('Area: ${intervention.area ?? "N/A"} ${intervention.areaUnit}'),
                          Text('Saved: ${intervention.timestamp.toDate().toString()}'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editIntervention(intervention),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteIntervention(intervention),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}