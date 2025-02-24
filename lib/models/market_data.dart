import 'package:cloud_firestore/cloud_firestore.dart';

class MarketData {
  final String? id; // Firestore document ID
  final String region;
  final String market;
  final String cropType;
  final double predictedPrice;
  final double retailPrice;
  final String userId;
  final Timestamp timestamp; // Added timestamp field

  MarketData({
    this.id,
    required this.region,
    required this.market,
    required this.cropType,
    required this.predictedPrice,
    required this.retailPrice,
    required this.userId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'region': region,
      'market': market,
      'cropType': cropType,
      'predictedPrice': predictedPrice,
      'retailPrice': retailPrice,
      'userId': userId,
      'timestamp': timestamp, // Include timestamp in map
    };
  }

  factory MarketData.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return MarketData(
      id: snapshot.id,
      region: data['region'] as String,
      market: data['market'] as String,
      cropType: data['cropType'] as String,
      predictedPrice: (data['predictedPrice'] as num).toDouble(),
      retailPrice: (data['retailPrice'] as num).toDouble(),
      userId: data['userId'] as String,
      timestamp: data['timestamp'] as Timestamp, // Parse timestamp
    );
  }

  factory MarketData.fromMap(Map<String, dynamic> map, String docId) {
    return MarketData(
      id: docId,
      region: map['region'] as String,
      market: map['market'] as String,
      cropType: map['cropType'] as String,
      predictedPrice: (map['predictedPrice'] as num).toDouble(),
      retailPrice: (map['retailPrice'] as num).toDouble(),
      userId: map['userId'] as String,
      timestamp: map['timestamp'] as Timestamp,
    );
  }
}