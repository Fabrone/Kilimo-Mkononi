import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kilimomkononi/models/pest_disease_model.dart'; // Now used

class AdminPestManagementPage extends StatefulWidget {
  const AdminPestManagementPage({super.key});

  @override
  State<AdminPestManagementPage> createState() => _AdminPestManagementPageState();
}

class _AdminPestManagementPageState extends State<AdminPestManagementPage> {
  List<PestIntervention> _interventions = []; // Changed to List<PestIntervention>

  @override
  void initState() {
    super.initState();
    _loadAllInterventions();
  }

  Future<void> _loadAllInterventions() async {
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('interventions')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      _interventions = snapshot.docs.map((doc) {
        final data = doc.data();
        return PestIntervention.fromMap(data, doc.id).copyWith(userId: doc.reference.parent.parent!.id);
      }).toList();
    });
  }

  Future<void> _restoreIntervention(String userId, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('pestinterventiondata')
          .doc(userId)
          .collection('interventions')
          .doc(docId)
          .update({'isDeleted': false});

      await FirebaseFirestore.instance.collection('User_logs').add({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'action': 'restore',
        'collection': 'pestinterventiondata',
        'documentId': docId,
        'timestamp': Timestamp.now(),
        'details': 'Restored intervention for user $userId',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intervention restored')));
        _loadAllInterventions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error restoring intervention: $e')));
      }
    }
  }

  Future<void> _hardDeleteIntervention(String userId, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Hard Deletion'),
        content: const Text('This will permanently delete the intervention. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('pestinterventiondata')
            .doc(userId)
            .collection('interventions')
            .doc(docId)
            .delete();

        await FirebaseFirestore.instance.collection('User_logs').add({
          'userId': FirebaseAuth.instance.currentUser!.uid,
          'action': 'hard_delete',
          'collection': 'pestinterventiondata',
          'documentId': docId,
          'timestamp': Timestamp.now(),
          'details': 'Hard-deleted intervention for user $userId',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intervention permanently deleted')));
          _loadAllInterventions();
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
        title: const Text('Admin Pest Management', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 3, 39, 4),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(16.0),
        child: _interventions.isEmpty
            ? const Center(child: Text('No interventions found.'))
            : ListView.builder(
                itemCount: _interventions.length,
                itemBuilder: (context, index) {
                  final intervention = _interventions[index];
                  final isDeleted = intervention.isDeleted;
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User: ${intervention.userId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Pest: ${intervention.pestName}'),
                          Text('Crop: ${intervention.cropType}'),
                          Text('Stage: ${intervention.cropStage}'),
                          Text('Intervention: ${intervention.intervention}'),
                          Text('Dosage: ${intervention.dosage ?? "N/A"} ${intervention.unit ?? ""}'),
                          Text('Area: ${intervention.area ?? "N/A"} ${intervention.areaUnit}'),
                          Text('Saved: ${intervention.timestamp.toDate().toString()}'),
                          Text('Deleted: $isDeleted', style: TextStyle(color: isDeleted ? Colors.red : Colors.green)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isDeleted)
                                IconButton(
                                  icon: const Icon(Icons.restore, color: Colors.green),
                                  onPressed: () => _restoreIntervention(intervention.userId, intervention.id!),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                onPressed: () => _hardDeleteIntervention(intervention.userId, intervention.id!),
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