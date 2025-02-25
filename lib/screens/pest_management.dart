import 'package:flutter/material.dart';
import 'package:kilimomkononi/models/pest_disease_model.dart';

class PestManagementPage extends StatefulWidget {
  const PestManagementPage({super.key});

  @override
  State<PestManagementPage> createState() => _PestManagementPageState();
}

class _PestManagementPageState extends State<PestManagementPage> {
  String? _selectedCrop;
  String? _selectedStage;
  String? _selectedPest;
  PestDiseaseData? _pestData;
  final _preventionController = TextEditingController();
  final _interventionController = TextEditingController();
  final _dosageController = TextEditingController();
  final _landAreaController = TextEditingController();
  final _effectivenessController = TextEditingController();
  final _causesController = TextEditingController();
  final _followUpController = TextEditingController();

  void _updatePestDetails() {
    if (_selectedPest != null && PestDiseaseData.pestLibrary.containsKey(_selectedPest)) {
      setState(() {
        _pestData = PestDiseaseData.pestLibrary[_selectedPest!];
        _preventionController.text = _pestData!.preventionStrategies.join('\n');
        _interventionController.text = 'Chemical control with ${_pestData!.activeAgent}';
        _dosageController.text = _pestData!.dosagePerLiter;
        _causesController.text = _pestData!.possibleCauses.join('\n');
        _followUpController.text = _pestData!.followUpActions.join('\n');
      });
    }
  }

  void _saveData() {
    if (_selectedCrop == null || _selectedStage == null || _selectedPest == null || _landAreaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    // Placeholder for saving to Firestore or local storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pest data saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              _buildDropdown('Crop Type', ['Maize', 'Beans', 'Tomatoes'], _selectedCrop, (val) => setState(() => _selectedCrop = val)),
              const SizedBox(height: 16),
              _buildDropdown('Crop Stage', [
                'Emergence/Planting',
                'Flowering',
                'Harvesting',
              ], _selectedStage, (val) => setState(() => _selectedStage = val)),
              const SizedBox(height: 16),
              _buildDropdown('Select Pest', PestDiseaseData.pestLibrary.keys.toList(), _selectedPest, (val) {
                setState(() => _selectedPest = val);
                _updatePestDetails();
              }),
              if (_pestData != null) ...[
                const SizedBox(height: 16),
                _buildImageCard(_pestData!.imagePath, _pestData!.description),
              ],
              const SizedBox(height: 16),
              _buildTextArea('Prevention Strategies', _preventionController, 'List prevention methods'),
              const SizedBox(height: 16),
              _buildTextArea('Intervention Used', _interventionController, 'Describe intervention'),
              const SizedBox(height: 16),
              _buildTextField('Dosage Required (per Liter)', _dosageController, 'e.g., 5ml/L'),
              const SizedBox(height: 16),
              _buildTextField('Total Area (SQM)', _landAreaController, 'Enter land area', isNumber: true),
              const SizedBox(height: 16),
              _buildTextArea('Effectiveness Evaluation', _effectivenessController, 'Evaluate effectiveness'),
              const SizedBox(height: 16),
              _buildTextArea('Possible Causes', _causesController, 'List possible causes'),
              const SizedBox(height: 16),
              _buildTextArea('Follow-Up Actions', _followUpController, 'List follow-up actions'),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 3, 39, 4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save'),
                ),
              ),
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

  Widget _buildTextArea(String label, TextEditingController controller, String hint) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextField(
          controller: controller,
          maxLines: 3,
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

  Widget _buildImageCard(String imagePath, String description) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Image.asset(imagePath, height: 150, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}