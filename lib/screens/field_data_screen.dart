import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz.initializeTimeZones(); // Initialize timezone data
  runApp(const MaterialApp(
    home: FieldDataScreen(),
  ));
}

class FieldDataScreen extends StatefulWidget {
  const FieldDataScreen({super.key});

  @override
  State<FieldDataScreen> createState() => _FieldDataScreenState();
}

class _FieldDataScreenState extends State<FieldDataScreen> {
  int? selectedPlot;
  List<int> plotNumbers = [];
  final Map<int, Map<String, dynamic>> _plotData = {};
  final _formKey = GlobalKey<FormState>();
  bool _useSQM = true;

  // Form field variables
  List<String> _crops = [];
  double? _plotArea;
  String? _cropStage;
  double? _nitrogen;
  double? _phosphorus;
  double? _potassium;
  String? _microNutrients;
  String? _intervention;
  String? _quantity;
  DateTime? _interventionDate;
  DateTime? _reminderDate;
  String? _reminderActivity;

  // Notification plugin instance
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  // Optimal N-P-K values per crop and stage (in kg/ha)
  static final Map<String, Map<String, Map<String, double>>> _optimalNPK = {
    'Maize': {
      'Emergence/Planting': {'N': 30.0, 'P': 15.0, 'K': 20.0},
      'Vegetative Growth': {'N': 50.0, 'P': 20.0, 'K': 30.0},
      'Flowering': {'N': 40.0, 'P': 25.0, 'K': 35.0},
      'Harvesting': {'N': 20.0, 'P': 10.0, 'K': 25.0},
    },
    'Beans': {
      'Emergence/Planting': {'N': 20.0, 'P': 30.0, 'K': 20.0},
      'Vegetative Growth': {'N': 25.0, 'P': 35.0, 'K': 25.0},
      'Flowering': {'N': 30.0, 'P': 40.0, 'K': 30.0},
      'Harvesting': {'N': 15.0, 'P': 20.0, 'K': 20.0},
    },
    'Wheat': {
      'Emergence/Planting': {'N': 25.0, 'P': 20.0, 'K': 15.0},
      'Tillering': {'N': 40.0, 'P': 25.0, 'K': 20.0},
      'Flowering': {'N': 35.0, 'P': 20.0, 'K': 25.0},
      'Harvesting': {'N': 20.0, 'P': 15.0, 'K': 20.0},
    },
    'Rice': {
      'Emergence/Planting': {'N': 30.0, 'P': 15.0, 'K': 20.0},
      'Tillering': {'N': 45.0, 'P': 20.0, 'K': 25.0},
      'Flowering': {'N': 40.0, 'P': 25.0, 'K': 30.0},
      'Harvesting': {'N': 25.0, 'P': 15.0, 'K': 20.0},
    },
    'Default': {
      'Default': {'N': 25.0, 'P': 15.0, 'K': 20.0},
    },
  };

  // Suggested micro nutrients per crop
  static final Map<String, String> _suggestedMicroNutrients = {
    'Maize': 'Zinc, Magnesium, Boron',
    'Beans': 'Iron, Molybdenum, Manganese',
    'Wheat': 'Copper, Zinc, Manganese',
    'Rice': 'Silicon, Iron, Zinc',
    'Default': 'General: Zinc, Iron, Magnesium',
  };

  String _getInterventionSuggestion(String crop, String? stage, double? n, double? p, double? k) {
    final optimal = _optimalNPK[crop]?[stage ?? 'Default'] ?? _optimalNPK['Default']!['Default']!;
    List<String> suggestions = [];
    if (n != null && n < optimal['N']!) suggestions.add('Add nitrogen fertilizer (${(optimal['N']! - n).toStringAsFixed(1)} kg/ha needed)');
    if (p != null && p < optimal['P']!) suggestions.add('Add phosphorus fertilizer (${(optimal['P']! - p).toStringAsFixed(1)} kg/ha needed)');
    if (k != null && k < optimal['K']!) suggestions.add('Add potassium fertilizer (${(optimal['K']! - k).toStringAsFixed(1)} kg/ha needed)');
    return suggestions.isNotEmpty ? suggestions.join(', ') : 'Levels are optimal';
  }

  String _getMicroNutrientSuggestion() {
    if (_crops.isEmpty) return _suggestedMicroNutrients['Default']!;
    String primaryCrop = _crops.first;
    return _suggestedMicroNutrients[primaryCrop] ?? _suggestedMicroNutrients['Default']!;
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPlotNumberDialog(context));
  }

  void _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);

    // Request notification permission for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _scheduleNotification(int plotId, DateTime scheduledDate, String activity) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'field_data_channel',
      'Field Data Reminders',
      channelDescription: 'Reminders for field activities',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    final tz.TZDateTime scheduledTZDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notificationsPlugin.zonedSchedule(
      plotId,
      'Field Reminder for Plot $plotId',
      'Activity: $activity',
      scheduledTZDateTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _showPlotNumberDialog(BuildContext context) async {
    int? numberOfPlots;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Number of Plots'),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter number of plots'),
          onChanged: (value) => numberOfPlots = int.tryParse(value),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (numberOfPlots != null && numberOfPlots! > 0) {
                setState(() {
                  plotNumbers.clear();
                  plotNumbers.addAll(List.generate(numberOfPlots!, (i) => i + 1));
                });
                Navigator.pop(context);
              } else if (mounted) { // Added mounted check
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid number greater than 0')),
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Field Data Input', semanticsLabel: 'Field Data Input Screen'),
          backgroundColor: Colors.green,
          actions: [
            IconButton(
              icon: Icon(_useSQM ? Icons.square_foot : Icons.agriculture),
              onPressed: () => setState(() => _useSQM = !_useSQM),
              tooltip: 'Toggle Units',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Input'),
              Tab(text: 'Summary'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInputTab(),
            _buildSummaryTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              plotNumbers.add(plotNumbers.length + 1);
            });
          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.add, semanticLabel: 'Add New Plot'),
        ),
      ),
    );
  }

  Widget _buildInputTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Plot Number',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: plotNumbers.map((plot) {
              final dynamic cropsDynamic = _plotData[plot]?['crops'];
              List<String> crops = cropsDynamic is List
                  ? List<String>.from(cropsDynamic.map((e) => e.toString()))
                  : [];
              return ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedPlot = plot;
                    _loadPlotData(plot);
                  });
                },
                onLongPress: () {
                  setState(() {
                    plotNumbers.remove(plot);
                    _plotData.remove(plot);
                    if (selectedPlot == plot) selectedPlot = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _plotData.containsKey(plot)
                      ? Colors.green.shade700
                      : selectedPlot == plot
                          ? Colors.green
                          : Colors.grey,
                  minimumSize: const Size(60, 48),
                ),
                child: Text(
                  crops.isNotEmpty ? 'Plot $plot (${crops.join(' + ')})' : 'Plot $plot',
                  semanticsLabel: 'Select Plot $plot${crops.isNotEmpty ? ' with ${crops.join(' and ')}' : ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (selectedPlot != null) _buildFieldDataForm(),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _plotData.length,
      itemBuilder: (context, index) {
        int plot = _plotData.keys.elementAt(index);
        var data = _plotData[plot]!;
        final dynamic cropsDynamic = data['crops'];
        List<String> crops = cropsDynamic is List
            ? List<String>.from(cropsDynamic.map((e) => e.toString()))
            : [];
        String primaryCrop = crops.isNotEmpty ? crops.first : 'Default';
        String suggestion = _getInterventionSuggestion(primaryCrop, data['cropStage'], data['nitrogen'], data['phosphorus'], data['potassium']);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Card(
            elevation: 2,
            child: ListTile(
              title: Text('Plot $plot', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Crops: ${crops.isNotEmpty ? crops.join(', ') : 'Not set'}'),
                  Text(
                    'Plot Area: ${data['plotArea'] != null ? (_useSQM ? data['plotArea'] : data['plotArea'] / 4046.86).toStringAsFixed(2) : 'N/A'} ${_useSQM ? 'SQM' : 'Acres'}',
                  ),
                  Text('Crop Stage: ${data['cropStage'] ?? 'Not set'}'),
                  Text(
                    'Nitrogen: ${data['nitrogen'] ?? 'N/A'} kg/ha (Opt: ${_optimalNPK[primaryCrop]?[data['cropStage'] ?? 'Default']?['N'] ?? _optimalNPK['Default']!['Default']!['N']} kg/ha)\n'
                    'Phosphorus: ${data['phosphorus'] ?? 'N/A'} kg/ha (Opt: ${_optimalNPK[primaryCrop]?[data['cropStage'] ?? 'Default']?['P'] ?? _optimalNPK['Default']!['Default']!['P']} kg/ha)\n'
                    'Potassium: ${data['potassium'] ?? 'N/A'} kg/ha (Opt: ${_optimalNPK[primaryCrop]?[data['cropStage'] ?? 'Default']?['K'] ?? _optimalNPK['Default']!['Default']!['K']} kg/ha)',
                  ),
                  Text('Micro Nutrients: ${data['microNutrients'] ?? 'Not set'}'),
                  Text('Intervention: ${data['intervention'] ?? 'Not set'}'),
                  Text('Quantity: ${data['quantity'] ?? 'Not set'}'),
                  Text('Intervention Date: ${data['interventionDate'] != null ? data['interventionDate'].toString().substring(0, 10) : 'Not set'}'),
                  Text('Reminder Date: ${data['reminderDate'] != null ? data['reminderDate'].toString().substring(0, 10) : 'Not set'}'),
                  Text('Reminder Activity: ${data['reminderActivity'] ?? 'Not set'}'),
                  const SizedBox(height: 8),
                  Text('Suggestion: $suggestion', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue)),
                ],
              ),
              trailing: Icon(
                data.isNotEmpty ? Icons.check_circle : Icons.warning,
                color: data.isNotEmpty ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldDataForm() {
    String primaryCrop = _crops.isNotEmpty ? _crops.first : 'Default';
    Map<String, double> optimalNPK = _optimalNPK[primaryCrop]?[_cropStage ?? 'Default'] ?? _optimalNPK['Default']!['Default']!;
    String? savedSuggestion = (_nitrogen != null && _phosphorus != null && _potassium != null && _cropStage != null)
        ? _getInterventionSuggestion(primaryCrop, _cropStage, _nitrogen, _phosphorus, _potassium)
        : null;

    return Form(
      key: _formKey,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Field Data for Plot $selectedPlot',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Crop Types (Multiple)
              ..._crops.map((crop) => Row(
                children: [
                  Expanded(child: Text(crop)),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => setState(() => _crops.remove(crop)),
                  ),
                ],
              )),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Add Crop Type',
                  hintText: 'Enter crop type and press Enter',
                ),
                onFieldSubmitted: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      _crops.add(value);
                      if (_crops.length == 1) _microNutrients = _getMicroNutrientSuggestion();
                    });
                    _formKey.currentState!.reset();
                  }
                },
                validator: (value) => _crops.isEmpty && (value == null || value.isEmpty) ? 'Please add at least one crop' : null,
              ),
              const SizedBox(height: 20),

              // Plot Area
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Plot Area (${_useSQM ? 'SQM' : 'Acres'})',
                  hintText: 'Enter plot area',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an area';
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Enter a valid positive number';
                  }
                  return null;
                },
                onSaved: (value) => _plotArea = _useSQM ? double.parse(value!) : double.parse(value!) * 4046.86,
                initialValue: _plotArea?.toString(),
              ),
              const SizedBox(height: 20),

              // Crop Stage
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Crop Stage'),
                items: [
                  'Emergence/Planting', 'Vegetative Growth', 'Tillering', 'Propagation', 'Transplanting',
                  'Germination', 'Weeding (1st Split)', 'Weeding (2nd Split)', 'Flowering', 'Fruiting',
                  'Podding', 'Harvesting', 'Post-Harvest'
                ].map((stage) => DropdownMenuItem(value: stage, child: Text(stage))).toList(),
                onChanged: (value) => setState(() => _cropStage = value),
                validator: (value) => value == null ? 'Please select a stage' : null,
                value: _cropStage,
              ),
              const SizedBox(height: 20),

              // Macro Nutrients (Collapsible)
              ExpansionTile(
                title: const Text('Macro Nutrients (N-P-K)', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  _buildNutrientField('Nitrogen (N) Level (kg/ha)', optimalNPK['N']!, (value) => _nitrogen = value, _nitrogen),
                  _buildNutrientField('Phosphorus (P) Level (kg/ha)', optimalNPK['P']!, (value) => _phosphorus = value, _phosphorus),
                  _buildNutrientField('Potassium (K) Level (kg/ha)', optimalNPK['K']!, (value) => _potassium = value, _potassium),
                ],
              ),
              const SizedBox(height: 20),

              // Micro Nutrients
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Micro Nutrients',
                  hintText: 'Suggested: ${_getMicroNutrientSuggestion()}',
                ),
                maxLines: 3,
                onSaved: (value) => _microNutrients = value ?? _getMicroNutrientSuggestion(),
                initialValue: _microNutrients,
              ),
              const SizedBox(height: 20),

              // Intervention Used (Free Text with Suggestion after N-P-K saved)
              ExpansionTile(
                title: const Text('Intervention Used', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Intervention Used'),
                    onSaved: (value) => _intervention = value,
                    initialValue: _intervention,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Quantity Used (Litres/Kg)'),
                    onSaved: (value) => _quantity = value,
                    initialValue: _quantity,
                  ),
                  ListTile(
                    title: Text(
                      'Intervention Date: ${_interventionDate != null ? _interventionDate!.toString().substring(0, 10) : 'Not set'}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _interventionDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _interventionDate = picked);
                    },
                  ),
                  ListTile(
                    title: Text(
                      'Reminder Date: ${_reminderDate != null ? _reminderDate!.toString().substring(0, 10) : 'Not set'}',
                    ),
                    trailing: const Icon(Icons.alarm),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _interventionDate?.add(const Duration(days: 7)) ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: _interventionDate ?? DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (pickedDate != null && mounted) { // Combined check for pickedDate and mounted
                        String? activity = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Set Reminder Activity'),
                            content: TextField(
                              decoration: const InputDecoration(hintText: 'Enter activity (e.g., Fertilize, Inspect)'),
                              onChanged: (value) => _reminderActivity = value,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, null),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, _reminderActivity),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        if (activity != null && activity.isNotEmpty) {
                          setState(() {
                            _reminderDate = pickedDate;
                            _reminderActivity = activity;
                          });
                          await _scheduleNotification(selectedPlot!, pickedDate, activity);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Reminder scheduled for Plot $selectedPlot on ${pickedDate.toString().substring(0, 10)}')),
                            );
                          }
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter an activity to set a reminder')),
                          );
                        }
                      }
                    },
                  ),
                  if (_reminderActivity != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Reminder Activity: $_reminderActivity',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  if (savedSuggestion != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Suggested Intervention: $savedSuggestion',
                        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Save', semanticsLabel: 'Save field data'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientField(String label, double optimal, Function(double?) onChanged, double? initialValue) {
    double? currentValue = initialValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: '$label (Optimal: $optimal kg/ha)',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter a value';
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Enter a valid positive number';
                }
                return null;
              },
              onSaved: (value) => onChanged(double.parse(value!)),
              onChanged: (value) => setState(() => currentValue = double.tryParse(value)),
              initialValue: initialValue?.toString(),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            currentValue != null && currentValue! < optimal ? Icons.warning : Icons.check,
            color: currentValue != null && currentValue! < optimal ? Colors.red : Colors.green,
            semanticLabel: currentValue != null && currentValue! < optimal ? 'Below optimal' : 'Optimal',
          ),
        ],
      ),
    );
  }

  void _loadPlotData(int plot) {
    final data = _plotData[plot];
    if (data != null) {
      final dynamic cropsDynamic = data['crops'];
      _crops = cropsDynamic is List ? List<String>.from(cropsDynamic.map((e) => e.toString())) : [];
      _plotArea = data['plotArea'] as double?;
      _cropStage = data['cropStage'] as String?;
      _nitrogen = data['nitrogen'] as double?;
      _phosphorus = data['phosphorus'] as double?;
      _potassium = data['potassium'] as double?;
      _microNutrients = data['microNutrients'] as String?;
      _intervention = data['intervention'] as String?;
      _quantity = data['quantity'] as String?;
      _interventionDate = data['interventionDate'] as DateTime?;
      _reminderDate = data['reminderDate'] as DateTime?;
      _reminderActivity = data['reminderActivity'] as String?;
    } else {
      _crops = [];
      _plotArea = null;
      _cropStage = null;
      _nitrogen = null;
      _phosphorus = null;
      _potassium = null;
      _microNutrients = null;
      _intervention = null;
      _quantity = null;
      _interventionDate = null;
      _reminderDate = null;
      _reminderActivity = null;
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _plotData[selectedPlot!] = {
          'crops': _crops.isNotEmpty ? List<String>.from(_crops) : ['Not set'],
          'plotArea': _plotArea,
          'cropStage': _cropStage,
          'nitrogen': _nitrogen,
          'phosphorus': _phosphorus,
          'potassium': _potassium,
          'microNutrients': _microNutrients,
          'intervention': _intervention,
          'quantity': _quantity,
          'interventionDate': _interventionDate ?? DateTime.now(),
          'reminderDate': _reminderDate,
          'reminderActivity': _reminderActivity,
        };
      });
      if (mounted) { // Added mounted check for safety, though not flagged here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data saved for Plot $selectedPlot on ${DateTime.now().toString().substring(0, 10)}')),
        );
      }
    }
  }
}