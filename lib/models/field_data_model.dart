import 'package:cloud_firestore/cloud_firestore.dart';

class FieldData {
  final String userId;
  final String plotId;
  final String? plotName;
  final List<Map<String, String>> crops;
  final double area;
  final Map<String, double> npk;
  final List<String> microNutrients;
  final List<Map<String, dynamic>> interventions;
  final List<Map<String, dynamic>> reminders;
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