import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:kilimomkononi/models/field_data_model.dart';
import 'package:kilimomkononi/screens/plot_summary_tab.dart';

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
  List<TextEditingController> _cropControllers = [];
  final _areaController = TextEditingController();
  final _nitrogenController = TextEditingController();
  final _phosphorusController = TextEditingController();
  final _potassiumController = TextEditingController();
  List<String> _microNutrients = [];
  List<TextEditingController> _microNutrientControllers = [TextEditingController()];
  List<Map<String, dynamic>> _interventions = [];
  List<Map<String, dynamic>> _reminders = [];

  final List<String> _cropStages = [
    'Planting', 'Emergence', 'Propagation', 'Transplanting', 'Weeding',
    'Flowering', 'Fruiting', 'Podding', 'Harvesting', 'Post-Harvest'
  ];
  final List<String> _commonUnits = ['Liters', 'Kg', 'Tons', 'Grams'];
  final Map<String, double> _optimalNpk = {'N': 30.0, 'P': 20.0, 'K': 25.0};

  @override
  void initState() {
    super.initState();
    _loadPlotData();
    _initializeCropFields();
  }

  void _initializeCropFields() {
    if (widget.plotId.contains('Intercrop') && _crops.isEmpty) {
      setState(() {
        _crops = [
          {'type': '', 'stage': ''},
          {'type': '', 'stage': ''},
        ];
        _cropControllers = [
          TextEditingController(),
          TextEditingController(),
        ];
      });
    } else if (_crops.isEmpty) {
      setState(() {
        _crops = [{'type': '', 'stage': ''}];
        _cropControllers = [TextEditingController()];
      });
    }
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
          _crops = data.crops.isNotEmpty ? data.crops : widget.plotId.contains('Intercrop') ? [{'type': '', 'stage': ''}, {'type': '', 'stage': ''}] : [{'type': '', 'stage': ''}];
          _cropControllers = _crops.map((crop) => TextEditingController(text: crop['type'])).toList();
          _areaController.text = data.area?.toString() ?? '';
          _nitrogenController.text = data.npk['N']?.toString() ?? '';
          _phosphorusController.text = data.npk['P']?.toString() ?? '';
          _potassiumController.text = data.npk['K']?.toString() ?? '';
          _microNutrients = data.microNutrients;
          _microNutrientControllers = data.microNutrients.map((m) => TextEditingController(text: m)).toList();
          if (_microNutrientControllers.isEmpty) _microNutrientControllers.add(TextEditingController());
          _interventions = data.interventions;
          _reminders = data.reminders;
        });
      } else if (widget.plotId.contains('Intercrop')) {
        setState(() {
          _crops = [
            {'type': '', 'stage': ''},
            {'type': '', 'stage': ''},
          ];
          _cropControllers = [
            TextEditingController(),
            TextEditingController(),
          ];
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
      _microNutrients = _microNutrientControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

      for (int i = 0; i < _cropControllers.length; i++) {
        if (_cropControllers[i].text.isNotEmpty) {
          _crops[i]['type'] = _cropControllers[i].text;
        }
      }
      _crops = _crops.where((crop) => crop['type']!.isNotEmpty).toList();

      try {
        final fieldData = FieldData(
          userId: widget.userId,
          plotId: widget.plotId,
          crops: _crops,
          area: _areaController.text.isNotEmpty ? (_useSQM ? double.parse(_areaController.text) : double.parse(_areaController.text) * 4046.86) : null,
          npk: {
            'N': _nitrogenController.text.isNotEmpty ? double.parse(_nitrogenController.text) : null,
            'P': _phosphorusController.text.isNotEmpty ? double.parse(_phosphorusController.text) : null,
            'K': _potassiumController.text.isNotEmpty ? double.parse(_potassiumController.text) : null,
          },
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
    final tzDayBefore = tz.TZDateTime.from(date.subtract(const Duration(days: 1)), tz.local);

    try {
      await widget.notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      await widget.notificationsPlugin.zonedSchedule(
        (widget.userId + widget.plotId + date.toString()).hashCode,
        'Reminder for ${widget.plotId}',
        activity,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      await widget.notificationsPlugin.zonedSchedule(
        ('${widget.userId}${widget.plotId}${date}dayBefore').hashCode,
        'Upcoming Reminder for ${widget.plotId}',
        'Reminder: $activity is due tomorrow!',
        tzDayBefore,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Reminders scheduled successfully')));
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('exact_alarms_not_permitted')) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Exact reminders not permitted. Please enable in device settings.')),
          );
        } else {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error scheduling reminder: $e')));
        }
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
            const Text('Add Crop', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._cropControllers.asMap().entries.map((entry) {
              int idx = entry.key;
              TextEditingController controller = entry.value;
              return Column(
                children: [
                  TextFormField(
                    controller: controller,
                    decoration: _inputDecoration('Crop Type ${idx + 1} (e.g., Maize)'),
                    validator: (value) => widget.plotId.contains('Intercrop') && idx < 2 && (value == null || value.isEmpty) ? 'Required for Intercrop' : null,
                    onChanged: (value) {
                      if (idx < _crops.length) {
                        _crops[idx]['type'] = value;
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildCropStageField(idx),
                  const SizedBox(height: 8),
                ],
              );
            }),
            if (widget.plotId.contains('Intercrop'))
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _crops.add({'type': '', 'stage': ''});
                    _cropControllers.add(TextEditingController());
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 3, 39, 4),
                  foregroundColor: Colors.white,
                ),
                child: const Text('+ Additional Crop'),
              ),
            const SizedBox(height: 16),

            const Text('Plot Area', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _areaController,
              decoration: _inputDecoration('Area (${_useSQM ? 'SQM' : 'Acres'})'),
              keyboardType: TextInputType.number,
              validator: (value) => value != null && value.isNotEmpty && double.tryParse(value) == null ? 'Enter a valid number' : null,
            ),
            SwitchListTile(
              title: const Text('Use Square Meters (SQM)'),
              value: _useSQM,
              onChanged: (value) => setState(() => _useSQM = value),
              activeColor: Colors.green[300],
            ),
            const SizedBox(height: 16),

            const Text('Soil Nutrient Levels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nitrogenController,
                      decoration: _inputDecoration('Nitrogen (N)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v != null && v.isNotEmpty && double.tryParse(v) == null ? 'Enter a valid number' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Optimal: ${_optimalNpk['N']}',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _phosphorusController,
                      decoration: _inputDecoration('Phosphorus (P)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v != null && v.isNotEmpty && double.tryParse(v) == null ? 'Enter a valid number' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Optimal: ${_optimalNpk['P']}',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _potassiumController,
                      decoration: _inputDecoration('Potassium (K)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v != null && v.isNotEmpty && double.tryParse(v) == null ? 'Enter a valid number' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Optimal: ${_optimalNpk['K']}',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text('Micro-Nutrients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Column(
              children: [
                ..._microNutrientControllers.map((controller) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: TextFormField(
                    controller: controller,
                    decoration: _inputDecoration('Add Micro-Nutrient (e.g., Zinc)'),
                    onFieldSubmitted: (value) {
                      if (value.isNotEmpty && !_microNutrients.contains(value)) {
                        setState(() => _microNutrients.add(value));
                      }
                    },
                  ),
                )),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _microNutrientControllers.add(TextEditingController()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 3, 39, 4),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Another Micro-Nutrient'),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: _microNutrients.map((m) => Chip(
                label: Text(m),
                onDeleted: () => setState(() => _microNutrients.remove(m)),
              )).toList(),
            ),
            const SizedBox(height: 16),

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
              mainAxisAlignment: MainAxisAlignment.center,
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropStageField(int index) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _cropStages;
        }
        return _cropStages.where((stage) => stage.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        setState(() {
          if (index < _crops.length) {
            _crops[index]['stage'] = selection;
          }
        });
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: _inputDecoration('Crop Stage ${index + 1} (e.g., Flowering)'),
          onFieldSubmitted: (value) {
            if (value.isNotEmpty && index < _crops.length) {
              setState(() {
                _crops[index]['stage'] = value;
              });
            }
            onFieldSubmitted();
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );

  Future<Map<String, dynamic>?> _showInterventionDialog() async {
    String? type;
    String? quantityText;
    String? unit;
    DateTime? date = DateTime.now();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Intervention'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: _inputDecoration('Intervention Type (e.g., Fertilizer)'),
                  onChanged: (value) => type = value,
                ),
                const SizedBox(height: 8),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                    return ['5', '10', '15', '20', '25'].where((option) => option.contains(textEditingValue.text));
                  },
                  onSelected: (String selection) {
                    quantityController.text = selection;
                    quantityText = selection;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    quantityController.text = controller.text;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: _inputDecoration('Quantity'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => quantityText = value,
                    );
                  },
                ),
                const SizedBox(height: 8),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return _commonUnits;
                    return _commonUnits.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    unitController.text = selection;
                    unit = selection;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    unitController.text = controller.text;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: _inputDecoration('Unit'),
                      onChanged: (value) => unit = value,
                    );
                  },
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final quantity = quantityText != null && quantityText!.isNotEmpty ? double.tryParse(quantityText!) : null;
              if (type != null && type!.isNotEmpty) {
                Navigator.pop(context, {
                  'type': type,
                  'quantity': quantity,
                  'unit': unit,
                  'date': Timestamp.fromDate(date!),
                });
              }
            },
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