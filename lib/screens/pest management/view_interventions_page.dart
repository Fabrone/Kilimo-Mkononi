import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kilimomkononi/models/pest_disease_model.dart';
import 'package:logger/logger.dart';
import 'package:timezone/timezone.dart' as tz;

class ViewInterventionsPage extends StatefulWidget {
  final PestData pestData; // Kept for navigation consistency, but not used for filtering
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  const ViewInterventionsPage({
    required this.pestData,
    required this.notificationsPlugin,
    super.key,
  });

  @override
  State<ViewInterventionsPage> createState() => _ViewInterventionsPageState();
}

class _ViewInterventionsPageState extends State<ViewInterventionsPage> {
  List<PestIntervention> _interventions = [];
  bool _isLoading = true;
  final _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadInterventions();
  }

  Future<void> _loadInterventions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _logger.w('No authenticated user found');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pestinterventiondata')
          .doc(user.uid)
          .collection('interventions')
          .where('isDeleted', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .get();
      _logger.i('Fetched ${snapshot.docs.length} interventions for user ${user.uid}');
      setState(() {
        _interventions = snapshot.docs.map((doc) => PestIntervention.fromMap(doc.data(), doc.id)).toList();
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading interventions: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editIntervention(PestIntervention intervention) async {
    final controller = TextEditingController(text: intervention.intervention);
    final amountController = TextEditingController(text: intervention.amount ?? '');
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
                TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount Applied')),
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
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final updatedIntervention = intervention.copyWith(
        intervention: controller.text,
        amount: amountController.text.isNotEmpty ? amountController.text : null,
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this intervention? It can be restored by an admin.'),
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
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Intervention deleted successfully')));
          setState(() {
            _interventions.removeWhere((i) => i.id == intervention.id);
          });
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error deleting intervention: $e')));
        }
      }
    }
  }

  Future<void> _scheduleFollowUp(PestIntervention intervention) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    DateTime? date = DateTime.now().add(const Duration(days: 7));

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Follow-Up Reminder'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Date: ${date!.toString().substring(0, 10)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date!,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => date = picked);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, {'date': date}),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final tzDateTime = tz.TZDateTime.from(result['date'] as DateTime, tz.local);
      const androidDetails = AndroidNotificationDetails(
        'pest_followup_channel',
        'Pest Follow-Up Reminders',
        channelDescription: 'Reminders for pest intervention follow-ups',
        importance: Importance.max,
        priority: Priority.high,
      );
      const notificationDetails = NotificationDetails(android: androidDetails);

      try {
        await widget.notificationsPlugin.zonedSchedule(
          intervention.id.hashCode,
          'Follow-Up for ${intervention.pestName}',
          'Evaluate effectiveness of ${intervention.intervention}',
          tzDateTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        if (mounted) {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Follow-up reminder scheduled')));
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error scheduling reminder: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Interventions', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 3, 39, 4),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _interventions.isEmpty
                ? const Center(child: Text('No data saved. Please add data and save to view interventions.'))
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
                              Text('Amount: ${intervention.amount ?? "N/A"}'),
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
                                  IconButton(
                                    icon: const Icon(Icons.notifications, color: Colors.green),
                                    onPressed: () => _scheduleFollowUp(intervention),
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