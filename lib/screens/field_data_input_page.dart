import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
//import 'package:timezone/timezone.dart' as tz;
import 'package:kilimomkononi/screens/plot_input_form.dart';
import 'package:kilimomkononi/screens/plot_summary_tab.dart';
import 'package:kilimomkononi/screens/plot_analytics_tab.dart';
//import 'package:kilimomkononi/models/field_data_model.dart';

class FieldDataInputPage extends StatefulWidget {
  final String userId; // Pass this from your app's auth system

  const FieldDataInputPage({required this.userId, super.key});

  @override
  State<FieldDataInputPage> createState() => _FieldDataInputPageState();
}

class _FieldDataInputPageState extends State<FieldDataInputPage> {
  String? _farmingScenario; // "multiple", "intercrop", "single"
  List<String> _plotIds = [];
  int _currentPlotIndex = 0;
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
    _loadFarmingScenario();
  }

  void _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _loadFarmingScenario() async {
    try {
    final snapshot = await FirebaseFirestore.instance
        .collection('fielddata')
        .where('userId', isEqualTo: widget.userId)
        .get();
      if (snapshot.docs.isEmpty) {
        _showOnboardingDialog();
      } else {
        setState(() {
          _plotIds = snapshot.docs.map((doc) => doc.id).toList();
          _farmingScenario = _plotIds.length > 1
              ? 'multiple'
              : _plotIds.first.contains('Intercrop')
                  ? 'intercrop'
                  : 'single';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _showOnboardingDialog() async {
    String? scenario;
    int? plotCount;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 3, 39, 4),
        title: const Text('Choose Farming Structure', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: scenario,
                dropdownColor: const Color.fromARGB(255, 3, 39, 4),
                items: const [
                  DropdownMenuItem(value: 'multiple', child: Text('Multiple Plots', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'intercrop', child: Text('Intercropping', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'single', child: Text('Single Crop', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (value) => setState(() => scenario = value),
              ),
              if (scenario == 'multiple')
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Number of plots',
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => plotCount = int.tryParse(value),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (scenario != null && (scenario != 'multiple' || (plotCount != null && plotCount! > 0))) {
                setState(() {
                  _farmingScenario = scenario;
                  if (scenario == 'multiple') {
                    _plotIds = List.generate(plotCount!, (i) => 'Plot ${i + 1}');
                  } else if (scenario == 'intercrop') {
                    _plotIds = ['Intercrop'];
                  } else {
                    _plotIds = ['SingleCrop'];
                  }
                });
                Navigator.pop(context);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a valid option')),
                );
              }
            },
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_farmingScenario == null) return const SizedBox(); // Wait for onboarding

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 3, 39, 4),
          title: const Text('Field Data Input', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: _showOnboardingDialog,
              child: const Text('Redefine Structure', style: TextStyle(color: Colors.white70)),
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.green[300],
            tabs: const [
              Tab(text: 'Input'),
              Tab(text: 'Summary'),
              Tab(text: 'Analytics'),
            ],
          ),
        ),
        body: _farmingScenario == 'multiple' && _plotIds.isNotEmpty
            ? TabBarView(
                children: [
                  Column(
                    children: [
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _plotIds.length,
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: () => setState(() => _currentPlotIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: _currentPlotIndex == index ? Colors.green[300] : Colors.transparent,
                              child: Text(_plotIds[index], style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: PlotInputForm(
                          userId: widget.userId,
                          plotId: _plotIds[_currentPlotIndex],
                          notificationsPlugin: _notificationsPlugin,
                        ),
                      ),
                    ],
                  ),
                  PlotSummaryTab(userId: widget.userId, plotIds: _plotIds),
                  PlotAnalyticsTab(userId: widget.userId, plotIds: _plotIds),
                ],
              )
            : TabBarView(
                children: [
                  PlotInputForm(
                    userId: widget.userId,
                    plotId: _plotIds.first,
                    notificationsPlugin: _notificationsPlugin,
                  ),
                  PlotSummaryTab(userId: widget.userId, plotIds: _plotIds),
                  PlotAnalyticsTab(userId: widget.userId, plotIds: _plotIds),
                ],
              ),
      ),
    );
  }
}