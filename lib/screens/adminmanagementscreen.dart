import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:kilimomkononi/screens/collection_management_screen.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final logger = Logger(printer: PrettyPrinter());
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedUserIds = [];
  List<String> _allCollections = [];

  @override
  void initState() {
    super.initState();
    _fetchCollections();
  }

  Future<void> _fetchCollections() async {
    try {
      setState(() {
        _allCollections = ['Users', 'marketdata', 'fielddata', 'pestdata', 'diseasedata', 'Admins', 'admin_logs'];
      });
    } catch (e) {
      logger.e('Error fetching collections: $e');
    }
  }

  Future<void> _assignAdminRole(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
      if (!userDoc.exists) throw 'User not found';
      await FirebaseFirestore.instance.collection('Admins').doc(uid).set({'added': true});
      _logActivity('Assigned admin role to $uid');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin role assigned successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error assigning admin role: $e')));
      }
    }
  }

  Future<void> _disableUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(uid).update({'isDisabled': true});
      _logActivity('Disabled user $uid');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User disabled successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error disabling user: $e')));
      }
    }
  }

  Future<void> _deleteUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(uid).delete();
      _logActivity('Deleted user $uid');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted from Firestore!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
      }
    }
  }

  Future<void> _resetPassword(String email) async {
    try {
      if (email.isEmpty) throw 'Email is required';
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _logActivity('Sent password reset for $email');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending password reset: $e')));
      }
    }
  }

  Future<void> _bulkDisableUsers() async {
    try {
      for (String uid in _selectedUserIds) {
        await FirebaseFirestore.instance.collection('Users').doc(uid).update({'isDisabled': true});
      }
      _logActivity('Bulk disabled users: ${_selectedUserIds.join(', ')}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected users disabled successfully!')));
      }
      setState(() => _selectedUserIds.clear());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error bulk disabling users: $e')));
      }
    }
  }

  Future<void> _bulkDeleteUsers() async {
    try {
      for (String uid in _selectedUserIds) {
        await FirebaseFirestore.instance.collection('Users').doc(uid).delete();
      }
      _logActivity('Bulk deleted users: ${_selectedUserIds.join(', ')}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected users deleted from Firestore!')));
      }
      setState(() => _selectedUserIds.clear());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error bulk deleting users: $e')));
      }
    }
  }

  Future<void> _exportCollectionToCsv(String collectionName) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection(collectionName).get();
      if (snapshot.docs.isEmpty) throw 'No data to export';
      List<List<dynamic>> csvData = [snapshot.docs.first.data().keys.toList()];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        csvData.add(data.values.map((v) => v.toString()).toList());
      }
      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getExternalStorageDirectory();
      final file = File('${directory!.path}/${collectionName}_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to ${file.path}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting $collectionName: $e')));
      }
    }
  }

  Future<void> _logActivity(String action) async {
    try {
      await FirebaseFirestore.instance.collection('admin_logs').add({
        'action': action,
        'timestamp': Timestamp.now(),
        'adminUid': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      logger.e('Error logging activity: $e');
    }
  }

  @override
  void dispose() {
    _uidController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
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
            const Text('Collection Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_allCollections.isEmpty)
              const CircularProgressIndicator()
            else
              ..._allCollections.map((collection) => StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection(collection).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final count = snapshot.data?.docs.length ?? 0;
                      return ListTile(
                        title: Text(collection, style: const TextStyle(fontSize: 16)),
                        trailing: Text('$count', style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 3, 39, 4))),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CollectionManagementScreen(collectionName: collection),
                          ),
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
        _buildOptionCard('Export Users', Icons.file_download, () => _exportCollectionToCsv('Users')),
        _buildOptionCard('Bulk Disable', Icons.block, _selectedUserIds.isNotEmpty ? _bulkDisableUsers : null),
        _buildOptionCard('Bulk Delete', Icons.delete_sweep, _selectedUserIds.isNotEmpty ? _bulkDeleteUsers : null),
        _buildOptionCard('Manage Users', Icons.people, () => _showManageUsersScreen()),
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a UID')));
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

  void _showManageUsersScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Manage Users', style: TextStyle(color: Colors.white)),
            backgroundColor: const Color.fromARGB(255, 3, 39, 4),
            foregroundColor: Colors.white,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No users found.'));
              }

              final users = snapshot.data!.docs;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Profile')),
                      DataColumn(label: Text('Full Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Farm Location')),
                      DataColumn(label: Text('Phone Number')),
                      DataColumn(label: Text('Gender')),
                      DataColumn(label: Text('National ID')),
                      DataColumn(label: Text('Date of Birth')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: users.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final uid = doc.id;
                      return DataRow(cells: [
                        DataCell(
                          data['profileImage'] != null
                              ? Image.memory(
                                  base64Decode(data['profileImage']),
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.person, size: 28),
                        ),
                        DataCell(Text(data['fullName'] ?? 'N/A')),
                        DataCell(Text(data['email'] ?? 'N/A')),
                        DataCell(Text(data['farmLocation'] ?? 'N/A')),
                        DataCell(Text(data['phoneNumber'] ?? 'N/A')),
                        DataCell(Text(data['gender'] ?? 'N/A')),
                        DataCell(Text(data['nationalId'] ?? 'N/A')),
                        DataCell(Text(data['dateOfBirth'] ?? 'N/A')),
                        DataCell(
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'Disable') _disableUser(uid);
                              if (value == 'Delete') _deleteUser(uid);
                              if (value == 'Reset Password') _resetPassword(data['email'] ?? '');
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'Disable', child: Text('Disable User')),
                              const PopupMenuItem(value: 'Delete', child: Text('Delete User')),
                              const PopupMenuItem(value: 'Reset Password', child: Text('Reset Password')),
                            ],
                            icon: const Icon(Icons.more_vert),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('User Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search Users',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            ),
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Users').snapshots(),
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
            final users = snapshot.data!.docs.where((doc) {
              final user = doc.data() as Map<String, dynamic>;
              final fullName = user['fullName']?.toString().toLowerCase() ?? '';
              final email = user['email']?.toString().toLowerCase() ?? '';
              return fullName.contains(_searchController.text.toLowerCase()) ||
                  email.contains(_searchController.text.toLowerCase());
            }).toList();
            return SizedBox(
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data() as Map<String, dynamic>;
                  final uid = users[index].id;
                  return ListTile(
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
                    title: Text(user['fullName'] ?? 'No Name'),
                    subtitle: Text('Email: ${user['email'] ?? 'N/A'}'),
                  );
                },
              ),
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
        const Text('Recent Activity Logs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('admin_logs').orderBy('timestamp', descending: true).limit(10).snapshots(),
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
        ),
      ],
    );
  }
}