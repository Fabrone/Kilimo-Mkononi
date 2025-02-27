import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:kilimomkononi/models/field_data_model.dart';
import 'package:kilimomkononi/screens/plot_summary_tab.dart';
import 'package:kilimomkononi/screens/plot_analytics_tab.dart';

class PlotInputForm extends StatefulWidget {
  final String userId;
  final String plotId;
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  const PlotInputForm({
    required this.userId,
    required this.plotId,
    required this.notificationsPlugin,
    super.key,
  });

  @override
  State<PlotInputForm> createState() => _PlotInputFormState();
}

class _PlotInputFormState extends State<PlotInputForm> {
  final _formKey = GlobalKey<FormState>();
  bool _useSQM = true;
  List<Map<String, String>> _crops = [];
  double? _area;
  double? _nitrogen;
  double? _phosphorus;
  double? _potassium;
  List<String> _microNutrients = [];
  List<Map<String, dynamic>> _interventions = [];
  List<Map<String, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadPlotData();
  }

  Future<void> _loadPlotData() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('fielddata')
          .doc('${widget.userId}_${widget.plotId}')
          .get();
      if (doc.exists) {
        final data = FieldData.fromMap(doc.data()!);
        setState(() {
          _crops = data.crops;
          _area = data.area;
          _nitrogen = data.npk['N'];
          _phosphorus = data.npk['P'];
          _potassium = data.npk['K'];
          _microNutrients = data.microNutrients;
          _interventions = data.interventions;
          _reminders = data.reminders;
        });
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error loading plot data: $e')));
      }
    }
  }

  Future<void> _saveForm() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        final fieldData = FieldData(
          userId: widget.userId,
          plotId: widget.plotId,
          crops: _crops,
          area: _area!,
          npk: {'N': _nitrogen!, 'P': _phosphorus!, 'K': _potassium!},
          microNutrients: _microNutrients,
          interventions: _interventions,
          reminders: _reminders,
          timestamp: Timestamp.now(),
        );
        await FirebaseFirestore.instance
            .collection('fielddata')
            .doc('${widget.userId}_${widget.plotId}')
            .set(fieldData.toMap());
        if (mounted) {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Data saved successfully')));
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error saving data: $e')));
        }
      }
    }
  }

  Future<void> _scheduleReminder(DateTime date, String activity) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    const androidDetails = AndroidNotificationDetails(
      'field_data_channel',
      'Field Data Reminders',
      channelDescription: 'Reminders for field activities',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    final tzDateTime = tz.TZDateTime.from(date, tz.local);

    try {
      await widget.notificationsPlugin.zonedSchedule(
        (widget.userId + widget.plotId + date.toString()).hashCode,
        'Reminder for ${widget.plotId}',
        activity,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      if (mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Reminder scheduled')));
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error scheduling reminder: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Crop
            const Text('Add Crop', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              decoration: _inputDecoration('Crop Type (e.g., Maize)'),
              onFieldSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    _crops.add({'type': value, 'stage': 'Emergence/Planting'});
                  });
                }
              },
            ),
            Wrap(
              spacing: 8,
              children: _crops.map((crop) => Chip(
                label: Text('${crop['type']} (${crop['stage']})'),
                onDeleted: () => setState(() => _crops.remove(crop)),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // Area
            const Text('Plot Area', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              decoration: _inputDecoration('Area (${_useSQM ? 'SQM' : 'Acres'})'),
              keyboardType: TextInputType.number,
              validator: (value) => value == null || double.tryParse(value) == null ? 'Enter a valid number' : null,
              onSaved: (value) => _area = _useSQM ? double.parse(value!) : double.parse(value!) * 4046.86,
            ),
            SwitchListTile(
              title: const Text('Use Square Meters (SQM)'),
              value: _useSQM,
              onChanged: (value) => setState(() => _useSQM = value),
              activeColor: Colors.green[300],
            ),
            const SizedBox(height: 16),

            // N-P-K
            const Text('Nutrient Levels (kg/ha)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _nutrientField('Nitrogen (N)', _nitrogen, (v) => _nitrogen = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _nutrientField('Phosphorus (P)', _phosphorus, (v) => _phosphorus = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _nutrientField('Potassium (K)', _potassium, (v) => _potassium = v),
            ),
            const SizedBox(height: 16),

            // Micro-Nutrients
            const Text('Micro-Nutrients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              decoration: _inputDecoration('Add Micro-Nutrient (e.g., Zinc)'),
              onFieldSubmitted: (value) {
                if (value.isNotEmpty) setState(() => _microNutrients.add(value));
              },
            ),
            Wrap(
              spacing: 8,
              children: _microNutrients.map((m) => Chip(
                label: Text(m),
                onDeleted: () => setState(() => _microNutrients.remove(m)),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // Interventions
            const Text('Interventions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final intervention = await _showInterventionDialog();
                if (intervention != null) setState(() => _interventions.add(intervention));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 3, 39, 4),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Intervention'),
            ),
            const SizedBox(height: 8),
            ..._interventions.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text('${i['type']} - ${i['quantity']} ${i['unit']}'),
                subtitle: Text((i['date'] as Timestamp).toDate().toString().substring(0, 10)),
              ),
            )),
            const SizedBox(height: 16),

            // Reminders
            const Text('Reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final reminder = await _showReminderDialog();
                if (reminder != null) {
                  setState(() => _reminders.add(reminder));
                  await _scheduleReminder(reminder['date'].toDate(), reminder['activity']);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 3, 39, 4),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Reminder'),
            ),
            const SizedBox(height: 8),
            ..._reminders.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(r['activity']),
                subtitle: Text(r['date'].toDate().toString().substring(0, 10)),
              ),
            )),
            const SizedBox(height: 16),

            // Save and Navigation Buttons
            ElevatedButton(
              onPressed: _saveForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 3, 39, 4),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Save', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlotSummaryTab(userId: widget.userId, plotIds: [widget.plotId]),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 3, 39, 4),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Summary'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlotAnalyticsTab(userId: widget.userId, plotIds: [widget.plotId]),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 3, 39, 4),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Analytics'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );

  Widget _nutrientField(String label, double? value, Function(double) onSaved) => TextFormField(
        decoration: _inputDecoration(label),
        keyboardType: TextInputType.number,
        validator: (v) => v == null || double.tryParse(v) == null || double.parse(v) > 500 ? 'Enter a valid value (max 500)' : null,
        onSaved: (v) => onSaved(double.parse(v!)),
        initialValue: value?.toString(),
      );

  Future<Map<String, dynamic>?> _showInterventionDialog() async {
    String? type;
    double? quantity;
    String? unit;
    DateTime? date = DateTime.now();
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Intervention'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: _inputDecoration('Intervention Type'),
                items: const [
                  DropdownMenuItem(value: 'Liquid', child: Text('Liquid Fertilizer')),
                  DropdownMenuItem(value: 'Granular', child: Text('Granular Fertilizer')),
                  DropdownMenuItem(value: 'Organic', child: Text('Organic Compost')),
                ],
                onChanged: (value) => setState(() => type = value),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: _inputDecoration('Quantity'),
                keyboardType: TextInputType.number,
                onChanged: (v) => quantity = double.tryParse(v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: unit,
                decoration: _inputDecoration('Unit'),
                items: const [
                  DropdownMenuItem(value: 'liters', child: Text('Liters')),
                  DropdownMenuItem(value: 'kg', child: Text('Kg')),
                  DropdownMenuItem(value: 'tons', child: Text('Tons')),
                ],
                onChanged: (value) => setState(() => unit = value),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text('Date: ${date!.toString().substring(0, 10)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date!,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => date = picked);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'type': type,
              'quantity': quantity,
              'unit': unit,
              'date': Timestamp.fromDate(date!),
            }),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showReminderDialog() async {
    DateTime? date = DateTime.now().add(const Duration(days: 7));
    String? activity;
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Reminder'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: _inputDecoration('Activity (e.g., Fertilize)'),
                onChanged: (v) => activity = v,
              ),
              const SizedBox(height: 8),
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
                  if (picked != null && mounted) setState(() => date = picked);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'date': Timestamp.fromDate(date!),
              'activity': activity,
            }),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}