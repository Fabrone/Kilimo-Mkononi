import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:kilimomkononi/screens/plot_input_form.dart';

class FieldDataInputPage extends StatefulWidget {
  final String userId; // Matches Firebase Auth UID from HomePage

  const FieldDataInputPage({required this.userId, super.key});

  @override
  State<FieldDataInputPage> createState() => _FieldDataInputPageState();
}

class _FieldDataInputPageState extends State<FieldDataInputPage> with SingleTickerProviderStateMixin {
  String? _farmingScenario;
  List<String> _plotIds = [];
  late TabController _tabController;
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
    _loadFarmingScenario();
    _tabController = TabController(length: 1, vsync: this); // Initial length, updated later
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _loadFarmingScenario() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('fielddata')
          .where('userId', isEqualTo: widget.userId)
          .get();
      if (snapshot.docs.isEmpty) {
        await _showOnboardingDialog();
      } else {
        setState(() {
          _plotIds = snapshot.docs.map((doc) => doc['plotId'] as String).toList();
          _farmingScenario = _plotIds.length > 1
              ? 'multiple'
              : _plotIds.first.contains('Intercrop')
                  ? 'intercrop'
                  : 'single';
          _tabController = TabController(length: _plotIds.length, vsync: this);
        });
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _showOnboardingDialog() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    String? scenario;
    int? plotCount;
    String? plotLabelPrefix;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          'Choose Your Farming Structure',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 3, 39, 4)),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: scenario,
                  decoration: const InputDecoration(
                    labelText: 'Farming Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'multiple', child: Text('Multiple Plots')),
                    DropdownMenuItem(value: 'intercrop', child: Text('Intercropping')),
                    DropdownMenuItem(value: 'single', child: Text('Single Crop')),
                  ],
                  onChanged: (value) => setState(() => scenario = value),
                ),
                if (scenario == 'multiple') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Number of Plots',
                      hintText: 'e.g., 3',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => plotCount = int.tryParse(value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Plot Label Prefix',
                      hintText: 'e.g., Plot, Field, Section',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) => plotLabelPrefix = value.isNotEmpty ? value : 'Plot',
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (scenario != null && (scenario != 'multiple' || (plotCount != null && plotCount! > 0))) {
                setState(() {
                  _farmingScenario = scenario;
                  if (scenario == 'multiple') {
                    _plotIds = List.generate(
                      plotCount!,
                      (i) => '${plotLabelPrefix ?? 'Plot'} ${i + 1}',
                    );
                  } else if (scenario == 'intercrop') {
                    _plotIds = ['Intercrop'];
                  } else {
                    _plotIds = ['SingleCrop'];
                  }
                  _tabController = TabController(length: _plotIds.length, vsync: this);
                });
                Navigator.pop(dialogContext);
              } else if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Please select a valid option')),
                );
              }
            },
            child: const Text('OK', style: TextStyle(color: Color.fromARGB(255, 3, 39, 4))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_farmingScenario == null) return const SizedBox();

    return DefaultTabController(
      length: _plotIds.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 3, 39, 4),
          title: const Text(
            'Field Data Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: const Color.fromRGBO(67, 145, 67, 1),
              tabs: _plotIds.map((plotId) => Tab(text: plotId)).toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _plotIds.map((plotId) {
                  return PlotInputForm(
                    userId: widget.userId,
                    plotId: plotId,
                    notificationsPlugin: _notificationsPlugin,
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _showOnboardingDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 3, 39, 4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Redefine Structure', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}