import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kilimomkononi/models/pest_disease_model.dart';
import 'package:timezone/timezone.dart' as tz;

class PestManagementPage extends StatefulWidget {
  const PestManagementPage({super.key});

  @override
  State<PestManagementPage> createState() => _PestManagementPageState();
}

class _PestManagementPageState extends State<PestManagementPage> {
  String? _selectedCrop;
  String? _selectedStage;
  String? _selectedPest;
  PestData? _pestData;
  bool _showPestDetails = false;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  final Map<String, List<String>> _cropPests = {
    'Maize': [
      'Termites', 'Cutworms', 'Maize Shoot Fly', 'Aphids', 'Stem Borers', 'Armyworms', 'Leafhoppers', 'Grasshoppers',
      'Earworms', 'Thrips', 'Weevils', 'Birds', 'Maize Weevil', 'Larger Grain Borer', 'Angoumois Grain Moth', 'Rodents'
    ],
    'Beans': [
      'Termites', 'Cutworms', 'Bean Fly', 'Aphids', 'Leafhoppers', 'Thrips', 'Pod Borers', 'Whiteflies', 'Beetles',
      'Bean Weevil', 'Bruchid Beetles', 'Rodents'
    ],
    'Tomatoes': [
      'Termites', 'Cutworms', 'Aphids', 'Whiteflies', 'Thrips', 'Leafminers', 'Spider Mites', 'Fruit Borers',
      'Tomato Hornworms', 'Nematodes', 'Stink Bugs', 'Bollworms', 'Tomato Leafminers', 'Fruit Flies', 'Beet Armyworms', 'Rodents'
    ],
    'Cassava': [
      'Termites', 'Mealybugs', 'Aphids', 'Whiteflies', 'Thrips', 'Spider Mites', 'Cassava Green Mite', 'Cassava Mosaic Virus Vectors',
      'Scale Insects', 'Grasshoppers', 'Rodents', 'Storage Weevils'
    ],
    'Rice': [
      'Termites', 'Cutworms', 'Rice Root Weevils', 'Stem Borers', 'Rice Gall Midges', 'Leafhoppers', 'Plant Hoppers', 'Rice Hispa',
      'Armyworms', 'Thrips', 'Aphids', 'Caseworms', 'Ear-Cutting Caterpillars', 'Rice Bug', 'Grain-Feeding Weevils', 'Rodents'
    ],
    'Potatoes': [
      'Termites', 'Cutworms', 'Aphids', 'Leafhoppers', 'Whiteflies', 'Thrips', 'Potato Tuber Moth', 'Colorado Potato Beetle',
      'Wireworms', 'Flea Beetles', 'Nematodes', 'Leafminers', 'Armyworms', 'Bollworms', 'Rodents'
    ],
    'Wheat': [
      'Termites', 'Cutworms', 'Aphids', 'Wireworms', 'Leafhoppers', 'Armyworms', 'Stem Borers', 'Wheat Midges', 'Hessian Fly',
      'Thrips', 'Grain Borers', 'Weevils', 'Rodents'
    ],
    'Cabbage/Kales': [
      'Termites', 'Cutworms', 'Aphids', 'Whiteflies', 'Thrips', 'Diamondback Moth', 'Cabbage Looper', 'Leafminers', 'Flea Beetles',
      'Cabbage Webworm', 'Armyworms', 'Stink Bugs', 'Cabbage Root Maggot', 'Rodents'
    ],
    'Sugarcane': [
      'Termites', 'Cutworms', 'Sugarcane Root Borers', 'White Grubs', 'Stem Borers', 'Sugarcane Top Shoot Borers', 'Leafhoppers',
      'Mealybugs', 'Whiteflies', 'Aphids', 'Scale Insects', 'Armyworms', 'Thrips', 'Rodents'
    ],
    'Carrots': [
      'Termites', 'Cutworms', 'Aphids', 'Leafhoppers', 'Whiteflies', 'Thrips', 'Carrot Rust Fly', 'Carrot Weevil', 'Nematodes',
      'Wireworms', 'Armyworms', 'Leafminers', 'Rodents'
    ],
  };

  final List<String> _cropStages = [
    'Emergence/Germination', 'Propagation', 'Transplanting', 'Weeding', 'Flowering',
    'Fruiting', 'Podding', 'Harvesting', 'Post-Harvest'
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _updatePestDetails() {
    if (_selectedPest != null && PestData.pestLibrary.containsKey(_selectedPest)) {
      setState(() {
        _pestData = PestData.pestLibrary[_selectedPest!];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pest Management', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 3, 39, 4),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown('Crop Type', _cropPests.keys.toList(), _selectedCrop, (val) {
                setState(() {
                  _selectedCrop = val;
                  _selectedPest = null; // Reset pest when crop changes
                  _pestData = null;
                });
              }),
              const SizedBox(height: 16),
              _buildAutocompleteField('Crop Stage', _cropStages),
              const SizedBox(height: 16),
              _buildDropdown('Select Pest', _selectedCrop != null ? _cropPests[_selectedCrop]! : [], _selectedPest, (val) {
                setState(() {
                  _selectedPest = val;
                  _updatePestDetails();
                });
              }),
              if (_pestData != null) ...[
                const SizedBox(height: 16),
                _buildImageCard(_pestData!.imagePath),
              ],
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  if (_pestData != null) {
                    setState(() => _showPestDetails = !_showPestDetails);
                  } else {
                    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Please select a pest first')));
                  }
                },
                child: const Text(
                  'View Pest Management Hints',
                  style: TextStyle(
                    color: Color.fromARGB(255, 3, 39, 4),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              if (_showPestDetails && _pestData != null) ...[
                const SizedBox(height: 8),
                _buildHintCard('Prevention Strategies', _pestData!.preventionStrategies.join('\n')),
                _buildHintCard('Possible Interventions', 'Chemical control with ${_pestData!.activeAgent}'),
                _buildHintCard('Possible Causes', _pestData!.possibleCauses.join('\n')),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InterventionPage(
                            pestData: _pestData!,
                            cropType: _selectedCrop!,
                            cropStage: _selectedStage ?? '',
                            notificationsPlugin: _notificationsPlugin,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 3, 39, 4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Manage Pest'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAutocompleteField(String label, List<String> options) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) return options;
            return options.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selection) => setState(() => _selectedStage = selection),
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: label,
              hintText: 'e.g., Flowering',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
            onSubmitted: (value) => setState(() => _selectedStage = value),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(String imagePath) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Image.asset(
          imagePath,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 150),
        ),
      ),
    );
  }

  Widget _buildHintCard(String title, String content) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class InterventionPage extends StatefulWidget {
  final PestData pestData;
  final String cropType;
  final String cropStage;
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  const InterventionPage({
    required this.pestData,
    required this.cropType,
    required this.cropStage,
    required this.notificationsPlugin,
    super.key,
  });

  @override
  State<InterventionPage> createState() => _InterventionPageState();
}

class _InterventionPageState extends State<InterventionPage> {
  final _interventionController = TextEditingController();
  final _dosageController = TextEditingController();
  final _unitController = TextEditingController();
  final _areaController = TextEditingController();
  bool _useSQM = true;
  List<PestIntervention> _interventions = [];

  @override
  void initState() {
    super.initState();
    _loadInterventions();
  }

  Future<void> _loadInterventions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('pestdata')
        .doc(user.uid)
        .collection('interventions')
        .where('pestName', isEqualTo: widget.pestData.name)
        .get();
    setState(() {
      _interventions = snapshot.docs.map((doc) => PestIntervention.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> _saveIntervention() async {
    final user = FirebaseAuth.instance.currentUser;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (user == null) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Please log in')));
      return;
    }
    if (_interventionController.text.isEmpty || _dosageController.text.isEmpty || _areaController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    final intervention = PestIntervention(
      pestName: widget.pestData.name,
      cropType: widget.cropType,
      cropStage: widget.cropStage,
      intervention: _interventionController.text,
      dosage: double.parse(_dosageController.text),
      unit: _unitController.text.isNotEmpty ? _unitController.text : 'ml',
      area: double.parse(_areaController.text),
      areaUnit: _useSQM ? 'SQM' : 'Acres',
      timestamp: Timestamp.now(),
    );

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('pestdata')
          .doc(user.uid)
          .collection('interventions')
          .add(intervention.toMap());
      setState(() {
        _interventions.add(intervention.copyWith(id: docRef.id));
        _interventionController.clear();
        _dosageController.clear();
        _unitController.clear();
        _areaController.clear();
      });
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Intervention saved successfully')));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error saving intervention: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Pest Intervention', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 3, 39, 4),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Intervention Used', _interventionController, 'e.g., Chemical control'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Dosage Applied', _dosageController, 'e.g., 5', isNumber: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('Unit', _unitController, 'e.g., ml'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Total Area Affected', _areaController, 'e.g., 100', isNumber: true),
                  ),
                  const SizedBox(width: 16),
                  SwitchListTile(
                    title: const Text('Use SQM'),
                    value: _useSQM,
                    onChanged: (value) => setState(() => _useSQM = value),
                    activeColor: Colors.green[300],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _saveIntervention,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 3, 39, 4),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Intervention'),
                  ),
                  ElevatedButton(
                    onPressed: _interventions.isEmpty
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewInterventionsPage(
                                  interventions: _interventions,
                                  pestData: widget.pestData,
                                  notificationsPlugin: widget.notificationsPlugin,
                                ),
                              ),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 3, 39, 4),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('View Saved Interventions'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool isNumber = false}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

class ViewInterventionsPage extends StatefulWidget {
  final List<PestIntervention> interventions;
  final PestData pestData;
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  const ViewInterventionsPage({
    required this.interventions,
    required this.pestData,
    required this.notificationsPlugin,
    super.key,
  });

  @override
  State<ViewInterventionsPage> createState() => _ViewInterventionsPageState();
}

class _ViewInterventionsPageState extends State<ViewInterventionsPage> {
  late List<PestIntervention> _interventions;

  @override
  void initState() {
    super.initState();
    _interventions = List.from(widget.interventions);
  }

  Future<void> _editIntervention(PestIntervention intervention) async {
    final controller = TextEditingController(text: intervention.intervention);
    final dosageController = TextEditingController(text: intervention.dosage.toString());
    final unitController = TextEditingController(text: intervention.unit);
    final areaController = TextEditingController(text: intervention.area.toString());
    bool useSQM = intervention.areaUnit == 'SQM';

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Intervention'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Intervention Used'),
              ),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(labelText: 'Dosage Applied'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: areaController,
                      decoration: const InputDecoration(labelText: 'Total Area Affected'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Use SQM'),
                    value: useSQM,
                    onChanged: (value) => useSQM = value,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isEmpty || dosageController.text.isEmpty || areaController.text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final updatedIntervention = intervention.copyWith(
        intervention: controller.text,
        dosage: double.parse(dosageController.text),
        unit: unitController.text,
        area: double.parse(areaController.text),
        areaUnit: useSQM ? 'SQM' : 'Acres',
      );

      final user = FirebaseAuth.instance.currentUser;
      try {
        await FirebaseFirestore.instance
            .collection('pestdata')
            .doc(user!.uid)
            .collection('interventions')
            .doc(intervention.id)
            .set(updatedIntervention.toMap());
        if (mounted) {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Intervention updated successfully')));
          setState(() {
            _interventions[_interventions.indexWhere((i) => i.id == intervention.id)] = updatedIntervention;
          });
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error updating intervention: $e')));
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
        content: const Text('Are you sure you want to delete this intervention?'),
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
      final user = FirebaseAuth.instance.currentUser;
      try {
        await FirebaseFirestore.instance
            .collection('pestdata')
            .doc(user!.uid)
            .collection('interventions')
            .doc(intervention.id)
            .delete();
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
          'Follow-Up for ${widget.pestData.name}',
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
        child: ListView.builder(
          itemCount: _interventions.length,
          itemBuilder: (context, index) {
            final intervention = _interventions[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(intervention.intervention),
                subtitle: Text(
                  'Dosage: ${intervention.dosage} ${intervention.unit}, Area: ${intervention.area} ${intervention.areaUnit}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
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
                      icon: const Icon(Icons.alarm, color: Colors.green),
                      onPressed: () => _scheduleFollowUp(intervention),
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