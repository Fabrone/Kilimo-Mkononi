import 'package:cloud_firestore/cloud_firestore.dart';

class FieldData {
  final String userId; // Matches the registered user's ID (e.g., from Firebase Auth)
  final String plotId; // e.g., "Plot 1", "Intercrop", "SingleCrop"
  final String? plotName; // Optional custom name
  final List<Map<String, String>> crops; // [{type: "Maize", stage: "Flowering"}, ...]
  final double area; // In SQM
  final Map<String, double> npk; // {N: 30.0, P: 15.0, K: 20.0}
  final List<String> microNutrients;
  final List<Map<String, dynamic>> interventions; // [{type: "Liquid", quantity: 5, unit: "liters", date: Timestamp}, ...]
  final List<Map<String, dynamic>> reminders; // [{date: Timestamp, activity: "Fertilize"}, ...]
  final Timestamp timestamp;

  FieldData({
    required this.userId,
    required this.plotId,
    this.plotName,
    required this.crops,
    required this.area,
    required this.npk,
    required this.microNutrients,
    required this.interventions,
    required this.reminders,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'plotId': plotId,
        'plotName': plotName,
        'crops': crops,
        'area': area,
        'npk': npk,
        'microNutrients': microNutrients,
        'interventions': interventions,
        'reminders': reminders,
        'timestamp': timestamp,
      };

  factory FieldData.fromMap(Map<String, dynamic> map) => FieldData(
        userId: map['userId'],
        plotId: map['plotId'],
        plotName: map['plotName'],
        crops: List<Map<String, String>>.from(map['crops']),
        area: map['area'],
        npk: Map<String, double>.from(map['npk']),
        microNutrients: List<String>.from(map['microNutrients']),
        interventions: List<Map<String, dynamic>>.from(map['interventions']),
        reminders: List<Map<String, dynamic>>.from(map['reminders']),
        timestamp: map['timestamp'],
      );
}