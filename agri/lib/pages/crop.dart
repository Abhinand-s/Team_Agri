import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Croppage extends StatefulWidget {
  @override
  _CroppageState createState() => _CroppageState();
}

class _CroppageState extends State<Croppage> {
  List<Crop> crops = [];
  List<Fertilizer> fertilizers = [];
  double totalEarnings = 0.0;
  double totalExpenses = 0.0;
  String _aiAdvice = '';
  bool _isLoadingAdvice = false;

  final TextEditingController cropNameController = TextEditingController();
  final TextEditingController cropCountController = TextEditingController();
  final TextEditingController cropPriceController = TextEditingController();

  final TextEditingController fertilizerNameController = TextEditingController();
  final TextEditingController fertilizerQuantityController = TextEditingController();
  final TextEditingController fertilizerCostController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    cropNameController.dispose();
    cropCountController.dispose();
    cropPriceController.dispose();
    fertilizerNameController.dispose();
    fertilizerQuantityController.dispose();
    fertilizerCostController.dispose();
    super.dispose();
  }

  Future<void> _addCrop() async {
    String name = cropNameController.text;
    int count = int.parse(cropCountController.text);
    double price = double.parse(cropPriceController.text);
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await _firestore.collection('crops').add({
      'name': name,
      'count': count,
      'price': price,
      'date': date,
    });

    cropNameController.clear();
    cropCountController.clear();
    cropPriceController.clear();
  }

  Future<void> _addFertilizer() async {
    String name = fertilizerNameController.text;
    double quantity = double.parse(fertilizerQuantityController.text);
    double cost = double.parse(fertilizerCostController.text);
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await _firestore.collection('fertilizers').add({
      'name': name,
      'quantity': quantity,
      'cost': cost,
      'date': date,
    });

    fertilizerNameController.clear();
    fertilizerQuantityController.clear();
    fertilizerCostController.clear();
  }

  Future<void> _deleteCrop(String id) async {
    await _firestore.collection('crops').doc(id).delete();
  }

  Future<void> _deleteFertilizer(String id) async {
    await _firestore.collection('fertilizers').doc(id).delete();
  }

  Future<void> _editCrop(String id, String name, int count, double price) async {
    await _firestore.collection('crops').doc(id).update({
      'name': name,
      'count': count,
      'price': price,
    });
  }

  Future<void> _editFertilizer(String id, String name, double quantity, double cost) async {
    await _firestore.collection('fertilizers').doc(id).update({
      'name': name,
      'quantity': quantity,
      'cost': cost,
    });
  }

  Future<void> _exportData() async {
    List<List<dynamic>> csvData = [];
    csvData.add(['Type', 'Name', 'Count/Quantity', 'Price/Cost', 'Date']);

    for (var crop in crops) {
      csvData.add(['Crop', crop.name, crop.count, crop.price, crop.date]);
    }

    for (var fertilizer in fertilizers) {
      csvData.add(['Fertilizer', fertilizer.name, fertilizer.quantity, fertilizer.cost, fertilizer.date]);
    }

    String csv = const ListToCsvConverter().convert(csvData);
    await Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data copied to clipboard!')));
  }

  Future<void> _fetchData() async {
    var cropSnapshot = await _firestore.collection('crops').get();
    var fertilizerSnapshot = await _firestore.collection('fertilizers').get();

    setState(() {
      crops = cropSnapshot.docs.map((doc) => Crop(doc['name'], doc['count'], doc['price'], doc['date'])).toList();
      fertilizers = fertilizerSnapshot.docs.map((doc) => Fertilizer(doc['name'], doc['quantity'], doc['cost'], doc['date'])).toList();
      _updateFinancialOverview();
    });
  }

  void _updateFinancialOverview() {
    totalEarnings = crops.fold(0.0, (sum, crop) => sum + (crop.count * crop.price));
    totalExpenses = fertilizers.fold(0.0, (sum, fertilizer) => sum + fertilizer.cost);
  }

  Future<void> _fetchAdvice() async {
    setState(() {
      _isLoadingAdvice = true;
      _aiAdvice = '';
    });
    
    try {
      final advice = await DeepSeekAIService.analyzeCropAndFertilizerData(
        crops: crops,
        fertilizers: fertilizers,
      );
      setState(() {
        _aiAdvice = advice;
      });
    } catch (e) {
      setState(() {
        _aiAdvice = 'Failed to fetch advice: $e';
      });
    } finally {
      setState(() {
        _isLoadingAdvice = false;
      });
    }
  }

  Widget _buildMoneyOverview() {
    double netProfit = totalEarnings - totalExpenses;

    return Card(
      color: Colors.green[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Financial Overview",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Total Earnings: ₹${totalEarnings.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Total Expenses: ₹${totalExpenses.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              "Net Profit: ₹${netProfit.toStringAsFixed(2)}",
              style: TextStyle(
                color: netProfit >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(String title, List<Widget> children) {
    return Card(
      color: Colors.green[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800])),
            ...children.map((child) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: child,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop & Fertilizer Management', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        actions: [
          IconButton(onPressed: _exportData, icon: Icon(Icons.download)),
          IconButton(onPressed: _fetchData, icon: Icon(Icons.refresh)),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMoneyOverview(),
            SizedBox(height: 20),
            _buildInputSection("Add Crop", [
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: cropNameController,
                  decoration: InputDecoration(labelText: "Crop Name", border: OutlineInputBorder()),
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: cropCountController,
                  decoration: InputDecoration(labelText: "Crop Count", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: cropPriceController,
                  decoration: InputDecoration(labelText: "Price per Crop", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addCrop,
                child: Text("Add Crop"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ]),
            SizedBox(height: 20),
            _buildInputSection("Add Fertilizer", [
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: fertilizerNameController,
                  decoration: InputDecoration(labelText: "Fertilizer Name", border: OutlineInputBorder()),
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: fertilizerQuantityController,
                  decoration: InputDecoration(labelText: "Quantity", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: fertilizerCostController,
                  decoration: InputDecoration(labelText: "Cost", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addFertilizer,
                child: Text("Add Fertilizer"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ]),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoadingAdvice ? null : _fetchAdvice,
              child: _isLoadingAdvice 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text("Get AI Advice"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                disabledBackgroundColor: Colors.blue.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 20),
            if (_isLoadingAdvice)
              Card(
                color: Colors.blue[50],
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text("Generating advice..."),
                    ],
                  ),
                ),
              ),
            if (_aiAdvice.isNotEmpty && !_isLoadingAdvice)
              Card(
                color: Colors.blue[50],
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    _aiAdvice,
                    style: TextStyle(fontSize: 16, color: Colors.blue[800]),
                  ),
                ),
              ),
            SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('crops').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }
                List<ChartData> chartData = [];
                snapshot.data!.docs.forEach((doc) {
                  chartData.add(ChartData(doc['name'], doc['count'].toDouble()));
                });
                return SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  title: ChartTitle(text: 'Crop Count Over Time', textStyle: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                  legend: Legend(isVisible: true),
                  series: <ChartSeries>[
                    ColumnSeries<ChartData, String>(
                      dataSource: chartData,
                      xValueMapper: (ChartData data, _) => data.label,
                      yValueMapper: (ChartData data, _) => data.value,
                      name: 'Crops',
                      color: Colors.green,
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('fertilizers').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }
                List<ChartData> chartData = [];
                snapshot.data!.docs.forEach((doc) {
                  chartData.add(ChartData(doc['name'], doc['quantity'].toDouble()));
                });
                return SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  title: ChartTitle(text: 'Fertilizer Usage Over Time', textStyle: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                  legend: Legend(isVisible: true),
                  series: <ChartSeries>[
                    ColumnSeries<ChartData, String>(
                      dataSource: chartData,
                      xValueMapper: (ChartData data, _) => data.label,
                      yValueMapper: (ChartData data, _) => data.value,
                      name: 'Fertilizer',
                      color: Colors.brown,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Crop {
  final String name;
  final int count;
  final double price;
  final String date;

  Crop(this.name, this.count, this.price, this.date);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
      'price': price,
      'date': date,
    };
  }
}

class Fertilizer {
  final String name;
  final double quantity;
  final double cost;
  final String date;

  Fertilizer(this.name, this.quantity, this.cost, this.date);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'cost': cost,
      'date': date,
    };
  }
}

class ChartData {
  final String label;
  final double value;
  ChartData(this.label, this.value);
}

class DeepSeekAIService {
  static const String _apiKey = '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';
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  static Future<String> analyzeCropAndFertilizerData({
    required List<Crop> crops,
    required List<Fertilizer> fertilizers,
  }) async {
    try {
      double totalEarnings = crops.fold(0.0, (sum, crop) => sum + (crop.count * crop.price));
      double totalExpenses = fertilizers.fold(0.0, (sum, fertilizer) => sum + fertilizer.cost);
      double netProfit = totalEarnings - totalExpenses;

      String inputData = jsonEncode({
        'crops': crops.map((crop) => crop.toJson()).toList(),
        'fertilizers': fertilizers.map((fertilizer) => fertilizer.toJson()).toList(),
        'totalEarnings': totalEarnings,
        'totalExpenses': totalExpenses,
        'netProfit': netProfit,
      });

      final Map<String, dynamic> requestBody = {
        "model": "deepseek/deepseek-r1-zero:free",
        "messages": [
          {
            "role": "user",
            "content": "Analyze this crop and fertilizer data and provide specific advice on how to increase profit. Consider the following data: $inputData. Provide recommendations on crop selection, fertilizer usage, cost reduction, and revenue optimization."
          }
        ]
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "<YOUR_SITE_URL>",
          "X-Title": "<YOUR_SITE_NAME>",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['choices'][0]['message']['content'] ?? 'No advice available.';
      } else {
        throw Exception('Failed to fetch advice: ${response.statusCode}');
      }
    } catch (e) {
      return 'Error connecting to OpenRouter AI: $e';
    }
  }
}