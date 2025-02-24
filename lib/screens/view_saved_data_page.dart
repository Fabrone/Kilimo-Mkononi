import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kilimomkononi/models/market_data.dart';

class ViewSavedDataPage extends StatefulWidget {
  const ViewSavedDataPage({super.key});

  @override
  ViewSavedDataPageState createState() => ViewSavedDataPageState();
}

class ViewSavedDataPageState extends State<ViewSavedDataPage> {
  void _deleteData(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('marketdata')
          .doc(docId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data deleted successfully!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete data: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _editData(MarketData data) async {
    if (!mounted) return;

    TextEditingController regionController = TextEditingController(text: data.region);
    TextEditingController marketController = TextEditingController(text: data.market);
    TextEditingController cropController = TextEditingController(text: data.cropType);
    TextEditingController retailPriceController = TextEditingController(text: data.retailPrice.toString());

    bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Market Data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: regionController,
                decoration: const InputDecoration(labelText: 'Region'),
              ),
              TextField(
                controller: marketController,
                decoration: const InputDecoration(labelText: 'Market'),
              ),
              TextField(
                controller: cropController,
                decoration: const InputDecoration(labelText: 'Crop Type'),
              ),
              TextField(
                controller: retailPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Retail Price (Ksh/kg)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (regionController.text.isEmpty ||
                  marketController.text.isEmpty ||
                  cropController.text.isEmpty ||
                  retailPriceController.text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('All fields must be filled')),
                );
                return;
              }

              double? retailPrice = double.tryParse(retailPriceController.text);
              if (retailPrice == null || retailPrice < 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Enter a valid retail price')),
                );
                return;
              }

              Navigator.pop(dialogContext, true); // Signal to save
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('marketdata')
            .doc(data.id)
            .update({
          'region': regionController.text,
          'market': marketController.text,
          'cropType': cropController.text,
          'retailPrice': double.parse(retailPriceController.text),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Data updated successfully!'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to update data: $e'),
                backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('View Saved Data'), backgroundColor: Colors.teal),
        body: const Center(child: Text('Please log in to view saved data.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Saved Data'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('marketdata')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true) // Sort by timestamp
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No saved data found.',
                    style: TextStyle(fontSize: 18)));
          }
          final dataList = snapshot.data!.docs
              .map((doc) => MarketData.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>, null))
              .toList();

          return ListView.builder(
            itemCount: dataList.length,
            itemBuilder: (context, index) {
              final data = dataList[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text('${data.cropType} - ${data.market}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Region: ${data.region}'),
                      Text(
                          'Predicted: Ksh ${data.predictedPrice.toStringAsFixed(2)}/kg'),
                      Text(
                          'Retail: Ksh ${data.retailPrice.toStringAsFixed(2)}/kg'),
                      Text(
                          'Saved on: ${data.timestamp.toDate().toString().substring(0, 19)}'), // Display timestamp
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editData(data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteData(data.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
