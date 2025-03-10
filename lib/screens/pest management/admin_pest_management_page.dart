import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kilimomkononi/models/pest_disease_model.dart';
import 'package:logger/logger.dart';

class AdminPestManagementPage extends StatefulWidget {
  const AdminPestManagementPage({super.key});

  @override
  State<AdminPestManagementPage> createState() => _AdminPestManagementPageState();
}

class _AdminPestManagementPageState extends State<AdminPestManagementPage> {
  List<PestIntervention> _interventions = [];
  bool _isLoading = true;
  final _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadAllInterventions();
  }

  Future<void> _loadAllInterventions() async {
    try {
      _logger.i('Loading all interventions for admin');
      final snapshot = await FirebaseFirestore.instance
          .collection('pestinterventiondata')
          .get();

      final allInterventions = <PestIntervention>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userInterventions = (data['interventions'] as List<dynamic>? ?? [])
            .map((item) => PestIntervention.fromMap(item as Map<String, dynamic>, item['id'] as String).copyWith(userId: doc.id))
            .toList();
        allInterventions.addAll(userInterventions);
      }

      allInterventions.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort descending

      if (mounted) {
        setState(() {
          _interventions = allInterventions;
          _isLoading = false;
        });
        _logger.i('Fetched ${_interventions.length} interventions');
      }
    } catch (e) {
      _logger.e('Error loading interventions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreIntervention(String userId, String interventionId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final docRef = FirebaseFirestore.instance.collection('pestinterventiondata').doc(userId);
      final doc = await docRef.get();
      final interventions = (doc.data()!['interventions'] as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final index = interventions.indexWhere((item) => item['id'] == interventionId);
      interventions[index]['isDeleted'] = false;

      await docRef.set({'interventions': interventions}, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('User_logs').add({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'action': 'restore',
        'collection': 'pestinterventiondata',
        'documentId': userId,
        'timestamp': Timestamp.now(),
        'details': 'Restored intervention for user $userId',
      });

      if (mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Intervention restored')));
        _logger.i('Restored intervention $interventionId for user $userId');
        _loadAllInterventions();
      }
    } catch (e) {
      _logger.e('Error restoring intervention $interventionId: $e');
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error restoring intervention: $e')));
      }
    }
  }

  Future<void> _hardDeleteIntervention(String userId, String interventionId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Hard Deletion'),
        content: const Text('This will permanently delete the intervention. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final docRef = FirebaseFirestore.instance.collection('pestinterventiondata').doc(userId);
        final doc = await docRef.get();
        final interventions = (doc.data()!['interventions'] as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        interventions.removeWhere((item) => item['id'] == interventionId);

        await docRef.set({'interventions': interventions}, SetOptions(merge: true));

        await FirebaseFirestore.instance.collection('User_logs').add({
          'userId': FirebaseAuth.instance.currentUser!.uid,
          'action': 'hard_delete',
          'collection': 'pestinterventiondata',
          'documentId': userId,
          'timestamp': Timestamp.now(),
          'details': 'Hard-deleted intervention for user $userId',
        });

        if (mounted) {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Intervention permanently deleted')));
          _logger.i('Hard-deleted intervention $interventionId for user $userId');
          _loadAllInterventions();
        }
      } catch (e) {
        _logger.e('Error hard-deleting intervention $interventionId: $e');
        if (mounted) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error deleting intervention: $e')));
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _interventions.isEmpty
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
                              Text('Intervention: ${intervention.intervention.isNotEmpty ? intervention.intervention : "None"}'),
                              Text('Amount: ${intervention.amount ?? "N/A"}'),
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