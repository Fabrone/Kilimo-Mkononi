import 'package:cloud_firestore/cloud_firestore.dart';

class PestData {
  final String name;
  final String imagePath;
  final List<String> preventionStrategies;
  final String activeAgent;
  final List<String> possibleCauses;

  PestData({
    required this.name,
    required this.imagePath,
    required this.preventionStrategies,
    required this.activeAgent,
    required this.possibleCauses,
  });

  static final Map<String, PestData> pestLibrary = {
    // Maize Pests
    'Termites': PestData(
      name: 'Termites',
      imagePath: 'assets/pests/termites.jpg',
      preventionStrategies: ['Crop rotation', 'Use of resistant varieties'],
      activeAgent: 'Imidacloprid',
      possibleCauses: ['Moist soil', 'Organic debris'],
    ),
    'Cutworms': PestData(
      name: 'Cutworms',
      imagePath: 'assets/pests/cutworms.jpg',
      preventionStrategies: ['Remove weeds', 'Ploughing before planting'],
      activeAgent: 'Lambda-cyhalothrin',
      possibleCauses: ['High humidity', 'Weedy fields'],
    ),
    // Add more pests as needed (sample for brevity)
    'Aphids': PestData(
      name: 'Aphids',
      imagePath: 'assets/pests/aphids.jpg',
      preventionStrategies: ['Introduce ladybugs', 'Regular monitoring'],
      activeAgent: 'Neem oil',
      possibleCauses: ['Warm weather', 'Over-fertilization'],
    ),
    // Placeholder for others - expand this library with real data
  };
}

class PestIntervention {
  final String? id;
  final String pestName;
  final String cropType;
  final String cropStage;
  final String intervention;
  final double dosage;
  final String unit;
  final double area;
  final String areaUnit;
  final Timestamp timestamp;

  PestIntervention({
    this.id,
    required this.pestName,
    required this.cropType,
    required this.cropStage,
    required this.intervention,
    required this.dosage,
    required this.unit,
    required this.area,
    required this.areaUnit,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'pestName': pestName,
        'cropType': cropType,
        'cropStage': cropStage,
        'intervention': intervention,
        'dosage': dosage,
        'unit': unit,
        'area': area,
        'areaUnit': areaUnit,
        'timestamp': timestamp,
      };

  factory PestIntervention.fromMap(Map<String, dynamic> map, String id) => PestIntervention(
        id: id,
        pestName: map['pestName'] as String,
        cropType: map['cropType'] as String,
        cropStage: map['cropStage'] as String,
        intervention: map['intervention'] as String,
        dosage: (map['dosage'] as num).toDouble(),
        unit: map['unit'] as String,
        area: (map['area'] as num).toDouble(),
        areaUnit: map['areaUnit'] as String,
        timestamp: map['timestamp'] as Timestamp,
      );

  PestIntervention copyWith({
    String? id,
    String? pestName,
    String? cropType,
    String? cropStage,
    String? intervention,
    double? dosage,
    String? unit,
    double? area,
    String? areaUnit,
    Timestamp? timestamp,
  }) => PestIntervention(
        id: id ?? this.id,
        pestName: pestName ?? this.pestName,
        cropType: cropType ?? this.cropType,
        cropStage: cropStage ?? this.cropStage,
        intervention: intervention ?? this.intervention,
        dosage: dosage ?? this.dosage,
        unit: unit ?? this.unit,
        area: area ?? this.area,
        areaUnit: areaUnit ?? this.areaUnit,
        timestamp: timestamp ?? this.timestamp,
      );
}