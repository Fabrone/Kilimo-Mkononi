import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CollectionManagementScreen extends StatefulWidget {
  final String collectionName;

  const CollectionManagementScreen({required this.collectionName, super.key});

  @override
  State<CollectionManagementScreen> createState() => _CollectionManagementScreenState();
}

class _CollectionManagementScreenState extends State<CollectionManagementScreen> {
  Future<void> _deleteDocument(String docId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance.collection(widget.collectionName).doc(docId).delete();
      if (mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Document deleted successfully!')));
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error deleting document: $e')));
      }
    }
  }

  Future<void> _editDocument(String docId, Map<String, dynamic> currentData) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final Map<String, TextEditingController> controllers = {};
    currentData.forEach((key, value) {
      controllers[key] = TextEditingController(text: value?.toString() ?? '');
    });

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit Document $docId'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: controllers.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText: entry.key,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controllers.map((key, controller) => MapEntry(key, controller.text))),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        await FirebaseFirestore.instance.collection(widget.collectionName).doc(docId).update(result);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Document updated successfully!')));
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error updating document: $e')));
      }
    }

    controllers.forEach((_, controller) => controller.dispose());
  }

  Future<void> _addDocument() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final TextEditingController idController = TextEditingController();
    final Map<String, TextEditingController> fieldControllers = {
      'field1': TextEditingController(),
      'field2': TextEditingController(),
    };

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Document'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  decoration: InputDecoration(
                    labelText: 'Document ID (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                ...fieldControllers.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: entry.key,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      fieldControllers['field${fieldControllers.length + 1}'] = TextEditingController();
                    });
                  },
                  child: const Text('Add Field'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'id': idController.text.isEmpty ? null : idController.text,
                'data': fieldControllers.map((key, controller) => MapEntry(key, controller.text)),
              }),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        final docRef = result['id'] == null
            ? FirebaseFirestore.instance.collection(widget.collectionName).doc()
            : FirebaseFirestore.instance.collection(widget.collectionName).doc(result['id']);
        await docRef.set(result['data']);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Document added successfully!')));
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error adding document: $e')));
      }
    }

    idController.dispose();
    fieldControllers.forEach((_, controller) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${widget.collectionName}', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 3, 39, 4),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addDocument,
            tooltip: 'Add New Document',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(widget.collectionName).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No documents found.'));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(doc.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data.entries.map((e) => '${e.key}: ${e.value}').join(', ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editDocument(doc.id, data),
                        tooltip: 'Edit Document',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteDocument(doc.id),
                        tooltip: 'Delete Document',
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