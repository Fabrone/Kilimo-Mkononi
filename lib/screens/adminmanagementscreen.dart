import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final logger = Logger(printer: PrettyPrinter());
  final TextEditingController _uidController = TextEditingController();
  String _sortField = 'fullName';
  bool _sortAscending = true;
  final List<String> _selectedUserIds = [];
  final List<String> _keyCollections = ['Users', 'marketdata'];

  Future<void> _assignAdminRole(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(uid).update({
        'role': 'admin',
      });
      _logActivity('Assigned admin role to $uid');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin role assigned successfully!')),
        );
      }
      logger.i('Admin role assigned to UID: $uid');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning admin role: $e')),
        );
      }
      logger.e('Error assigning admin role: $e');
    }
  }

  Future<void> _disableUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(uid).update({
        'isDisabled': true,
      });
      _logActivity('Disabled user $uid');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User account disabled successfully!')),
        );
      }
      logger.i('User disabled: $uid');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error disabling user: $e')),
        );
      }
      logger.e('Error disabling user: $e');
    }
  }

  Future<void> _deleteUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(uid).delete();
      _logActivity('Deleted user $uid');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted from Firestore!')),
        );
      }
      logger.i('User deleted from Firestore: $uid');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: $e')),
        );
      }
      logger.e('Error deleting user: $e');
    }
  }

  Future<void> _resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _logActivity('Sent password reset for $email');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        );
      }
      logger.i('Password reset email sent to: $email');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending password reset: $e')),
        );
      }
      logger.e('Error sending password reset: $e');
    }
  }

  Future<void> _bulkDisableUsers() async {
    try {
      for (String uid in _selectedUserIds) {
        await FirebaseFirestore.instance.collection('Users').doc(uid).update({
          'isDisabled': true,
        });
      }
      _logActivity('Bulk disabled users: ${_selectedUserIds.join(', ')}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected users disabled successfully!')),
        );
      }
      setState(() => _selectedUserIds.clear());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error bulk disabling users: $e')),
        );
      }
      logger.e('Error bulk disabling users: $e');
    }
  }

  Future<void> _bulkDeleteUsers() async {
    try {
      for (String uid in _selectedUserIds) {
        await FirebaseFirestore.instance.collection('Users').doc(uid).delete();
      }
      _logActivity('Bulk deleted users: ${_selectedUserIds.join(', ')}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected users deleted from Firestore!')),
        );
      }
      setState(() => _selectedUserIds.clear());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error bulk deleting users: $e')),
        );
      }
      logger.e('Error bulk deleting users: $e');
    }
  }

  Future<void> _logActivity(String action) async {
    await FirebaseFirestore.instance.collection('admin_logs').add({
      'action': action,
      'timestamp': Timestamp.now(),
      'adminUid': FirebaseAuth.instance.currentUser?.uid,
    });
  }

  Future<void> _exportUsersToCsv() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('Users').get();
    List<List<dynamic>> csvData = [
      ['UID', 'Name', 'Email', 'Age', 'Gender', 'Phone', 'Location', 'National ID', 'Status'],
    ];
    for (var doc in usersSnapshot.docs) {
      final user = doc.data();
      final age = user['dateOfBirth'] != null ? _calculateAge(user['dateOfBirth']) : 'N/A';
      csvData.add([
        doc.id,
        user['fullName'] ?? 'N/A',
        user['email'] ?? 'N/A',
        age,
        user['gender'] ?? 'N/A',
        user['phoneNumber'] ?? 'N/A',
        user['location'] ?? 'N/A',
        user['nationalId'] ?? 'N/A',
        user['isDisabled'] == true ? 'Disabled' : 'Active',
      ]);
    }
    String csv = const ListToCsvConverter().convert(csvData);
    final directory = await getExternalStorageDirectory();
    final file = File('${directory!.path}/users_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Users exported to ${file.path}')),
      );
    }
  }

  int _calculateAge(Timestamp dob) {
    DateTime birthDate = dob.toDate();
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Management', style: TextStyle(color: Colors.white)),
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
              const Text(
                'Admin Dashboard',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 3, 39, 4)),
              ),
              const SizedBox(height: 20),
              _buildCollectionStats(),
              const SizedBox(height: 20),
              _buildManagementOptions(),
              const SizedBox(height: 20),
              _buildUserList(),
              const SizedBox(height: 20),
              _buildActivityLogs(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionStats() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Collection Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._keyCollections.map((collection) => StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection(collection).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    final count = snapshot.data?.docs.length ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(collection, style: const TextStyle(fontSize: 16)),
                          Text('$count', style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 3, 39, 4))),
                        ],
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementOptions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildOptionCard('Assign Admin', Icons.person_add, () => _showAssignAdminDialog()),
        _buildOptionCard('Export Users', Icons.file_download, _exportUsersToCsv),
        _buildOptionCard('Bulk Disable', Icons.block, _selectedUserIds.isNotEmpty ? _bulkDisableUsers : null),
        _buildOptionCard('Bulk Delete', Icons.delete_sweep, _selectedUserIds.isNotEmpty ? _bulkDeleteUsers : null),
      ],
    );
  }

  Widget _buildOptionCard(String title, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: onTap == null ? Colors.grey[300] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: const Color.fromARGB(255, 3, 39, 4)),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignAdminDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Admin Role'),
        content: TextField(
          controller: _uidController,
          decoration: InputDecoration(
            labelText: 'Enter User UID',
            hintText: 'e.g., abc123xyz789',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_uidController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a UID')),
                );
                return;
              }
              _assignAdminRole(_uidController.text);
              Navigator.pop(context);
              _uidController.clear();
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Management',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            DropdownButton<String>(
              value: _sortField,
              items: const [
                DropdownMenuItem(value: 'fullName', child: Text('Name')),
                DropdownMenuItem(value: 'email', child: Text('Email')),
                DropdownMenuItem(value: 'age', child: Text('Age')),
                DropdownMenuItem(value: 'gender', child: Text('Gender')),
                DropdownMenuItem(value: 'phoneNumber', child: Text('Phone')),
                DropdownMenuItem(value: 'location', child: Text('Location')),
                DropdownMenuItem(value: 'nationalId', child: Text('National ID')),
              ],
              onChanged: (value) {
                setState(() {
                  _sortField = value!;
                });
              },
            ),
            IconButton(
              icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
              onPressed: () {
                setState(() {
                  _sortAscending = !_sortAscending;
                });
              },
            ),
          ],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .orderBy(_sortField == 'age' ? 'dateOfBirth' : _sortField, descending: !_sortAscending)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No users found.');
            }
            final users = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index].data() as Map<String, dynamic>;
                final uid = users[index].id;
                final age = user['dateOfBirth'] != null ? _calculateAge(user['dateOfBirth']) : 'N/A';
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Checkbox(
                      value: _selectedUserIds.contains(uid),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedUserIds.add(uid);
                          } else {
                            _selectedUserIds.remove(uid);
                          }
                        });
                      },
                    ),
                    title: Text(user['fullName'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${user['email'] ?? 'N/A'}'),
                        Text('Age: $age'),
                        Text('Gender: ${user['gender'] ?? 'N/A'}'),
                        Text('Phone: ${user['phoneNumber'] ?? 'N/A'}'),
                        Text('Location: ${user['location'] ?? 'N/A'}'),
                        Text('National ID: ${user['nationalId'] ?? 'N/A'}'),
                        Text('Status: ${user['isDisabled'] == true ? 'Disabled' : 'Active'}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.block, color: Colors.orange),
                          onPressed: () => _disableUser(uid),
                          tooltip: 'Disable User',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(uid),
                          tooltip: 'Delete User',
                        ),
                        IconButton(
                          icon: const Icon(Icons.lock_reset, color: Colors.blue),
                          onPressed: () => _resetPassword(user['email'] ?? ''),
                          tooltip: 'Reset Password',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityLogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity Logs',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('admin_logs')
              .orderBy('timestamp', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No recent activity logs.');
            }
            final logs = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index].data() as Map<String, dynamic>;
                final timestamp = (log['timestamp'] as Timestamp).toDate();
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(log['action']),
                    subtitle: Text('By: ${log['adminUid']} at $timestamp'),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}