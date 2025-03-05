import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kilimomkononi/models/pest_disease_model.dart';
import 'package:kilimomkononi/screens/intervention_page.dart';

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
                  _selectedPest = null;
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
                _buildHintCard('Herbicides', _pestData!.herbicides.join('\n')),
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 56, // Account for padding and card margins
            maxHeight: MediaQuery.of(context).size.height * 0.4, // Limit to 40% of screen height
          ),
          child: FutureBuilder<Size>(
            future: _getImageSize(imagePath),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                return const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final imageSize = snapshot.data!;
              return AspectRatio(
                aspectRatio: imageSize.width / imageSize.height,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 150),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<Size> _getImageSize(String imagePath) async {
    final Completer<Size> completer = Completer();
    final Image image = Image.asset(imagePath);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          completer.complete(Size(info.image.width.toDouble(), info.image.height.toDouble()));
        },
        onError: (exception, stackTrace) {
          completer.complete(const Size(150, 150)); // Default size on error
        },
      ),
    );
    return completer.future;
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