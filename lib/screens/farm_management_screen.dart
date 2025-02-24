import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MaterialApp(home: FarmManagementScreen()));
}

class FarmManagementScreen extends StatefulWidget {
  const FarmManagementScreen({super.key});

  @override
  State<FarmManagementScreen> createState() => _FarmManagementScreenState();
}

class _FarmManagementScreenState extends State<FarmManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SharedPreferences _prefs;

  // Form controllers
  final _labourCostController = TextEditingController();
  DateTime _labourActivityDate = DateTime.now();
  String? _selectedLabourActivity;
  final _equipmentCostController = TextEditingController();
  String? _selectedEquipmentActivity;
  final _inputCostController = TextEditingController();
  String? _selectedInputActivity;
  final _cropGrownController = TextEditingController();
  final _revenueController = TextEditingController();
  final _totalProductionCostController = TextEditingController();
  final _profitLossController = TextEditingController();
  final _loanAmountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _loanInterestController = TextEditingController();
  final _totalRepaymentController = TextEditingController();
  final _remainingBalanceController = TextEditingController();
  final _paymentAmountController = TextEditingController();
  DateTime _paymentDate = DateTime.now();

  // Lists to store data
  List<Map<String, dynamic>> _labourActivities = [];
  List<Map<String, dynamic>> _mechanicalCosts = [];
  List<Map<String, dynamic>> _inputCosts = [];
  List<Map<String, dynamic>> _revenues = [];
  List<Map<String, dynamic>> _paymentHistory = [];

  // Dropdown options
  final List<String> _labourActivitiesOptions = ['Ploughing', 'Fertilizing', 'Harvesting', 'Weeding'];
  final List<String> _equipmentActivitiesOptions = ['Tractor Use', 'Irrigation Pump', 'Harvester'];
  final List<String> _inputActivitiesOptions = ['Seeds', 'Fertilizer', 'Pesticides'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _labourActivities = (_prefs.getString('labourActivities') != null)
          ? List<Map<String, dynamic>>.from(jsonDecode(_prefs.getString('labourActivities')!))
          : [];
      _mechanicalCosts = (_prefs.getString('mechanicalCosts') != null)
          ? List<Map<String, dynamic>>.from(jsonDecode(_prefs.getString('mechanicalCosts')!))
          : [];
      _inputCosts = (_prefs.getString('inputCosts') != null)
          ? List<Map<String, dynamic>>.from(jsonDecode(_prefs.getString('inputCosts')!))
          : [];
      _revenues = (_prefs.getString('revenues') != null)
          ? List<Map<String, dynamic>>.from(jsonDecode(_prefs.getString('revenues')!))
          : [];
      _paymentHistory = (_prefs.getString('paymentHistory') != null)
          ? List<Map<String, dynamic>>.from(jsonDecode(_prefs.getString('paymentHistory')!))
          : [];
      _loadLoanData();
      _calculateTotalProductionCost();
      _calculateProfitLoss();
    });
  }

  void _calculateTotalProductionCost() {
    double totalCost = 0;
    for (var item in _labourActivities) {
      totalCost += double.parse(item['cost']);
    }
    for (var item in _mechanicalCosts) {
      totalCost += double.parse(item['cost']);
    }
    for (var item in _inputCosts) {
      totalCost += double.parse(item['cost']);
    }
    _totalProductionCostController.text = totalCost.toStringAsFixed(2);
    _calculateProfitLoss();
  }

  void _calculateProfitLoss() {
    double totalCost = double.parse(_totalProductionCostController.text.isEmpty ? '0' : _totalProductionCostController.text);
    double totalRevenue = _revenues.fold(0, (sum, rev) => sum + double.parse(rev['amount']));
    double profitLoss = totalRevenue - totalCost;
    _profitLossController.text = profitLoss.toStringAsFixed(2);
  }

  void _updateLoanCalculations() {
    double loanAmount = double.tryParse(_loanAmountController.text) ?? 0;
    double interestRate = double.tryParse(_interestRateController.text) ?? 0;
    double interest = (loanAmount * interestRate) / 100;
    double totalRepayment = loanAmount + interest;

    _loanInterestController.text = interest.toStringAsFixed(2);
    _totalRepaymentController.text = totalRepayment.toStringAsFixed(2);
    _remainingBalanceController.text = totalRepayment.toStringAsFixed(2);

    _saveLoanData(loanAmount, interestRate, interest, totalRepayment);
  }

  void _saveLoanData(double loanAmount, double interestRate, double interest, double totalRepayment) {
    _prefs.setString('loanData', jsonEncode({
      'loanAmount': loanAmount,
      'interestRate': interestRate,
      'interest': interest,
      'totalRepayment': totalRepayment,
      'remainingBalance': totalRepayment,
    }));
  }

  void _loadLoanData() {
    String? savedLoanData = _prefs.getString('loanData');
    if (savedLoanData != null) {
      Map<String, dynamic> loanData = jsonDecode(savedLoanData);
      _loanAmountController.text = loanData['loanAmount'].toString();
      _interestRateController.text = loanData['interestRate'].toString();
      _loanInterestController.text = loanData['interest'].toStringAsFixed(2);
      _totalRepaymentController.text = loanData['totalRepayment'].toStringAsFixed(2);
      _remainingBalanceController.text = loanData['remainingBalance'].toStringAsFixed(2);
    }
  }

  void _recordPayment() {
    double paymentAmount = double.tryParse(_paymentAmountController.text) ?? 0;
    double remainingBalance = double.tryParse(_remainingBalanceController.text) ?? 0;

    if (paymentAmount > 0 && paymentAmount <= remainingBalance) {
      remainingBalance -= paymentAmount;
      _remainingBalanceController.text = remainingBalance.toStringAsFixed(2);

      final newPayment = {
        'date': _paymentDate.toIso8601String().substring(0, 10),
        'amount': paymentAmount.toString(),
        'remainingBalance': remainingBalance.toString(),
      };
      setState(() {
        _paymentHistory.insert(0, newPayment);
        _prefs.setString('paymentHistory', jsonEncode(_paymentHistory));
        _paymentAmountController.clear();
        _paymentDate = DateTime.now();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid payment amount')));
    }
  }

  void _saveForm() {
    _prefs.setString('labourActivities', jsonEncode(_labourActivities));
    _prefs.setString('mechanicalCosts', jsonEncode(_mechanicalCosts));
    _prefs.setString('inputCosts', jsonEncode(_inputCosts));
    _prefs.setString('revenues', jsonEncode(_revenues));
    _prefs.setString('paymentHistory', jsonEncode(_paymentHistory));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data Saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save All Data',
            onPressed: _saveForm,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
            Tab(text: 'Costs', icon: Icon(Icons.money_off)),
            Tab(text: 'Revenue', icon: Icon(Icons.attach_money)),
            Tab(text: 'Profit/Loss', icon: Icon(Icons.account_balance)),
            Tab(text: 'Loans', icon: Icon(Icons.account_balance_wallet)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Dashboard Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: _labourActivities.fold(0.0, (sum, item) => sum! + double.parse(item['cost'])),
                          color: Colors.red,
                          title: 'Labour',
                        ),
                        PieChartSectionData(
                          value: _mechanicalCosts.fold(0.0, (sum, item) => sum! + double.parse(item['cost'])),
                          color: Colors.blue,
                          title: 'Equipment',
                        ),
                        PieChartSectionData(
                          value: _inputCosts.fold(0.0, (sum, item) => sum! + double.parse(item['cost'])),
                          color: Colors.orange,
                          title: 'Inputs',
                        ),
                        PieChartSectionData(
                          value: _revenues.fold(0.0, (sum, item) => sum! + double.parse(item['amount'])),
                          color: Colors.green,
                          title: 'Revenue',
                        ),
                        PieChartSectionData(
                          value: double.parse(_profitLossController.text.isEmpty ? '0' : _profitLossController.text).abs(),
                          color: double.parse(_profitLossController.text.isEmpty ? '0' : _profitLossController.text) >= 0 ? Colors.purple : Colors.grey,
                          title: double.parse(_profitLossController.text.isEmpty ? '0' : _profitLossController.text) >= 0 ? 'Profit' : 'Loss',
                        ),
                      ],
                    ),
                  ),
                ),
                Card(child: ListTile(title: const Text('Total Costs'), subtitle: Text('KSH ${_totalProductionCostController.text}'))),
                Card(child: ListTile(title: const Text('Total Revenue'), subtitle: Text('KSH ${_revenues.fold(0.0, (sum, item) => sum + double.parse(item['amount'])).toStringAsFixed(2)}'))),
                Card(child: ListTile(title: const Text('Profit/Loss'), subtitle: Text('KSH ${_profitLossController.text}'))),
              ],
            ),
          ),
          // Costs Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  color: Colors.red[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Labour Costs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        DropdownButtonFormField<String>(
                          value: _selectedLabourActivity,
                          decoration: const InputDecoration(labelText: 'Activity', prefixIcon: Icon(Icons.work)),
                          items: _labourActivitiesOptions.map((activity) => DropdownMenuItem(value: activity, child: Text(activity))).toList(),
                          onChanged: (value) => setState(() => _selectedLabourActivity = value),
                        ),
                        TextFormField(controller: _labourCostController, decoration: const InputDecoration(labelText: 'Cost (KSH)', prefixIcon: Icon(Icons.currency_exchange)), keyboardType: TextInputType.number),
                        ListTile(
                          title: Text('Date: ${_labourActivityDate.toString().substring(0, 10)}'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(context: context, initialDate: _labourActivityDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (picked != null) setState(() => _labourActivityDate = picked);
                          },
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_selectedLabourActivity != null && _labourCostController.text.isNotEmpty) {
                              final newActivity = {
                                'activity': _selectedLabourActivity!,
                                'cost': _labourCostController.text,
                                'date': _labourActivityDate.toIso8601String().substring(0, 10),
                              };
                              setState(() {
                                _labourActivities.insert(0, newActivity);
                                _prefs.setString('labourActivities', jsonEncode(_labourActivities));
                                _selectedLabourActivity = null;
                                _labourCostController.clear();
                                _calculateTotalProductionCost();
                              });
                            }
                          },
                          child: const Text('Add Labour Cost'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_labourActivities.isNotEmpty)
                  ListTile(
                    title: Text('Latest Labour: ${_labourActivities.first['activity']} - KSH ${_labourActivities.first['cost']}'),
                    subtitle: Text('Date: ${_labourActivities.first['date']}'),
                  ),
                Card(
                  color: Colors.blue[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Mechanical Costs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        DropdownButtonFormField<String>(
                          value: _selectedEquipmentActivity,
                          decoration: const InputDecoration(labelText: 'Equipment', prefixIcon: Icon(Icons.agriculture)),
                          items: _equipmentActivitiesOptions.map((activity) => DropdownMenuItem(value: activity, child: Text(activity))).toList(),
                          onChanged: (value) => setState(() => _selectedEquipmentActivity = value),
                        ),
                        TextFormField(controller: _equipmentCostController, decoration: const InputDecoration(labelText: 'Cost (KSH)', prefixIcon: Icon(Icons.currency_exchange)), keyboardType: TextInputType.number),
                        ElevatedButton(
                          onPressed: () {
                            if (_selectedEquipmentActivity != null && _equipmentCostController.text.isNotEmpty) {
                              final newCost = {
                                'activity': _selectedEquipmentActivity!,
                                'cost': _equipmentCostController.text,
                                'date': DateTime.now().toIso8601String().substring(0, 10),
                              };
                              setState(() {
                                _mechanicalCosts.insert(0, newCost);
                                _prefs.setString('mechanicalCosts', jsonEncode(_mechanicalCosts));
                                _selectedEquipmentActivity = null;
                                _equipmentCostController.clear();
                                _calculateTotalProductionCost();
                              });
                            }
                          },
                          child: const Text('Add Equipment Cost'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_mechanicalCosts.isNotEmpty)
                  ListTile(
                    title: Text('Latest Equipment: ${_mechanicalCosts.first['activity']} - KSH ${_mechanicalCosts.first['cost']}'),
                    subtitle: Text('Date: ${_mechanicalCosts.first['date']}'),
                  ),
                Card(
                  color: Colors.orange[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Input Costs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        DropdownButtonFormField<String>(
                          value: _selectedInputActivity,
                          decoration: const InputDecoration(labelText: 'Input', prefixIcon: Icon(Icons.local_florist)),
                          items: _inputActivitiesOptions.map((activity) => DropdownMenuItem(value: activity, child: Text(activity))).toList(),
                          onChanged: (value) => setState(() => _selectedInputActivity = value),
                        ),
                        TextFormField(controller: _inputCostController, decoration: const InputDecoration(labelText: 'Cost (KSH)', prefixIcon: Icon(Icons.currency_exchange)), keyboardType: TextInputType.number),
                        ElevatedButton(
                          onPressed: () {
                            if (_selectedInputActivity != null && _inputCostController.text.isNotEmpty) {
                              final newCost = {
                                'activity': _selectedInputActivity!,
                                'cost': _inputCostController.text,
                                'date': DateTime.now().toIso8601String().substring(0, 10),
                              };
                              setState(() {
                                _inputCosts.insert(0, newCost);
                                _prefs.setString('inputCosts', jsonEncode(_inputCosts));
                                _selectedInputActivity = null;
                                _inputCostController.clear();
                                _calculateTotalProductionCost();
                              });
                            }
                          },
                          child: const Text('Add Input Cost'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_inputCosts.isNotEmpty)
                  ListTile(
                    title: Text('Latest Input: ${_inputCosts.first['activity']} - KSH ${_inputCosts.first['cost']}'),
                    subtitle: Text('Date: ${_inputCosts.first['date']}'),
                  ),
              ],
            ),
          ),
          // Revenue Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  color: Colors.green[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Revenue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        TextFormField(controller: _cropGrownController, decoration: const InputDecoration(labelText: 'Crop Grown', prefixIcon: Icon(Icons.grass))),
                        TextFormField(controller: _revenueController, decoration: const InputDecoration(labelText: 'Revenue (KSH)', prefixIcon: Icon(Icons.attach_money)), keyboardType: TextInputType.number),
                        ElevatedButton(
                          onPressed: () {
                            if (_cropGrownController.text.isNotEmpty && _revenueController.text.isNotEmpty) {
                              final newRevenue = {
                                'crop': _cropGrownController.text,
                                'amount': _revenueController.text,
                              };
                              setState(() {
                                _revenues.insert(0, newRevenue);
                                _prefs.setString('revenues', jsonEncode(_revenues));
                                _cropGrownController.clear();
                                _revenueController.clear();
                                _calculateTotalProductionCost();
                              });
                            }
                          },
                          child: const Text('Add Revenue'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _revenues.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text('${_revenues[index]['crop']} - KSH ${_revenues[index]['amount']}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Profit/Loss Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Profit/Loss', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        TextFormField(controller: _totalProductionCostController, decoration: const InputDecoration(labelText: 'Total Cost (KSH)'), readOnly: true),
                        TextFormField(controller: _profitLossController, decoration: const InputDecoration(labelText: 'Profit/Loss (KSH)'), readOnly: true),
                        ElevatedButton(onPressed: _calculateProfitLoss, child: const Text('Calculate Profit/Loss')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Loans Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  color: Colors.purple[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Loan Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        TextFormField(controller: _loanAmountController, decoration: const InputDecoration(labelText: 'Loan Amount (KSH)', prefixIcon: Icon(Icons.account_balance_wallet)), keyboardType: TextInputType.number, onChanged: (_) => _updateLoanCalculations()),
                        TextFormField(controller: _interestRateController, decoration: const InputDecoration(labelText: 'Interest Rate (%)', prefixIcon: Icon(Icons.percent)), keyboardType: TextInputType.number, onChanged: (_) => _updateLoanCalculations()),
                        TextFormField(controller: _loanInterestController, decoration: const InputDecoration(labelText: 'Interest (KSH)'), readOnly: true),
                        TextFormField(controller: _totalRepaymentController, decoration: const InputDecoration(labelText: 'Total Repayment (KSH)'), readOnly: true),
                        TextFormField(controller: _remainingBalanceController, decoration: const InputDecoration(labelText: 'Remaining Balance (KSH)'), readOnly: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Colors.purple[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Loan Payments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        TextFormField(controller: _paymentAmountController, decoration: const InputDecoration(labelText: 'Payment Amount (KSH)', prefixIcon: Icon(Icons.payment)), keyboardType: TextInputType.number),
                        ListTile(
                          title: Text('Payment Date: ${_paymentDate.toString().substring(0, 10)}'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(context: context, initialDate: _paymentDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (picked != null) setState(() => _paymentDate = picked);
                          },
                        ),
                        ElevatedButton(onPressed: _recordPayment, child: const Text('Record Payment')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _paymentHistory.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text('${_paymentHistory[index]['date']} - KSH ${_paymentHistory[index]['amount']}'),
                      subtitle: Text('Remaining: KSH ${_paymentHistory[index]['remainingBalance']}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivitiesScreen(
              labourActivities: _labourActivities,
              mechanicalCosts: _mechanicalCosts,
              inputCosts: _inputCosts,
              revenues: _revenues,
              paymentHistory: _paymentHistory,
              totalCosts: _totalProductionCostController.text,
              profitLoss: _profitLossController.text,
              onDelete: (category, index) {
                setState(() {
                  switch (category) {
                    case 'labour':
                      _labourActivities.removeAt(index);
                      _prefs.setString('labourActivities', jsonEncode(_labourActivities));
                      break;
                    case 'mechanical':
                      _mechanicalCosts.removeAt(index);
                      _prefs.setString('mechanicalCosts', jsonEncode(_mechanicalCosts));
                      break;
                    case 'input':
                      _inputCosts.removeAt(index);
                      _prefs.setString('inputCosts', jsonEncode(_inputCosts));
                      break;
                    case 'revenue':
                      _revenues.removeAt(index);
                      _prefs.setString('revenues', jsonEncode(_revenues));
                      break;
                    case 'payment':
                      _paymentHistory.removeAt(index);
                      _prefs.setString('paymentHistory', jsonEncode(_paymentHistory));
                      break;
                  }
                  _calculateTotalProductionCost();
                  Navigator.pop(context); // Return to main screen to refresh UI
                });
              },
            ),
          ),
        ).then((_) {
          // Refresh state when returning from ActivitiesScreen
          setState(() {});
        }),
        tooltip: 'View All Activities',
        child: const Icon(Icons.list),
      ),
    );
  }
}

// Updated ActivitiesScreen with Total Costs, Profit/Loss, and Delete Functionality
class ActivitiesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> labourActivities;
  final List<Map<String, dynamic>> mechanicalCosts;
  final List<Map<String, dynamic>> inputCosts;
  final List<Map<String, dynamic>> revenues;
  final List<Map<String, dynamic>> paymentHistory;
  final String totalCosts;
  final String profitLoss;
  final Function(String, int) onDelete;

  const ActivitiesScreen({
    super.key,
    required this.labourActivities,
    required this.mechanicalCosts,
    required this.inputCosts,
    required this.revenues,
    required this.paymentHistory,
    required this.totalCosts,
    required this.profitLoss,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Farm Activities')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(child: ListTile(title: const Text('Total Costs'), subtitle: Text('KSH $totalCosts'))),
            Card(child: ListTile(title: const Text('Profit/Loss'), subtitle: Text('KSH $profitLoss'))),
            const SizedBox(height: 20),
            const Text('Labour Activities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: labourActivities.length,
              itemBuilder: (context, index) => ListTile(
                title: Text('${labourActivities[index]['activity']} - KSH ${labourActivities[index]['cost']}'),
                subtitle: Text('Date: ${labourActivities[index]['date']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    onDelete('labour', index);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Mechanical Costs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mechanicalCosts.length,
              itemBuilder: (context, index) => ListTile(
                title: Text('${mechanicalCosts[index]['activity']} - KSH ${mechanicalCosts[index]['cost']}'),
                subtitle: Text('Date: ${mechanicalCosts[index]['date']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    onDelete('mechanical', index);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Input Costs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: inputCosts.length,
              itemBuilder: (context, index) => ListTile(
                title: Text('${inputCosts[index]['activity']} - KSH ${inputCosts[index]['cost']}'),
                subtitle: Text('Date: ${inputCosts[index]['date']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    onDelete('input', index);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Revenues', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: revenues.length,
              itemBuilder: (context, index) => ListTile(
                title: Text('${revenues[index]['crop']} - KSH ${revenues[index]['amount']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    onDelete('revenue', index);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Loan Payments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paymentHistory.length,
              itemBuilder: (context, index) => ListTile(
                title: Text('${paymentHistory[index]['date']} - KSH ${paymentHistory[index]['amount']}'),
                subtitle: Text('Remaining: KSH ${paymentHistory[index]['remainingBalance']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    onDelete('payment', index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}