class PestDiseaseData {
  final String name;
  final String imagePath; // Placeholder for local assets or URLs
  final String description;
  final String activeAgent;
  final String dosagePerLiter; // e.g., "10ml/L"
  final List<String> preventionStrategies;
  final List<String> possibleCauses;
  final List<String> followUpActions;

  PestDiseaseData({
    required this.name,
    required this.imagePath,
    required this.description,
    required this.activeAgent,
    required this.dosagePerLiter,
    required this.preventionStrategies,
    required this.possibleCauses,
    required this.followUpActions,
  });

  // Sample predefined data
  static final Map<String, PestDiseaseData> pestLibrary = {
    'ants': PestDiseaseData(
      name: 'Ants',
      imagePath: 'assets/pests/ants.jpg', // Add to assets folder
      description: 'Small insects that feed on plant sap and seeds.',
      activeAgent: 'Imidacloprid',
      dosagePerLiter: '5ml/L',
      preventionStrategies: ['Crop rotation', 'Remove plant debris'],
      possibleCauses: ['Overwatering', 'Poor soil drainage'],
      followUpActions: ['Monitor weekly', 'Apply bait traps'],
    ),
    'caterpillar': PestDiseaseData(
      name: 'Caterpillar',
      imagePath: 'assets/pests/caterpillar.jpg',
      description: 'Larvae that chew leaves and stems.',
      activeAgent: 'Spinosad',
      dosagePerLiter: '2ml/L',
      preventionStrategies: ['Introduce natural predators', 'Use row covers'],
      possibleCauses: ['Warm weather', 'Dense planting'],
      followUpActions: ['Check leaves daily', 'Reapply after rain'],
    ),
  };
}