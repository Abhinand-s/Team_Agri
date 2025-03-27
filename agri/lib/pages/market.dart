import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MarketDashboard extends StatefulWidget {
  @override
  _MarketDashboardState createState() => _MarketDashboardState();
}

class _MarketDashboardState extends State<MarketDashboard> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> categories = ['Vegetables', 'Tools', 'Fertilizers', 'Seeds', 'Irrigation'];

  // List to store data fetched from the Google Apps Script web app
  List<Map<String, dynamic>> marketData = [];

  // Map to store data grouped by category
  Map<String, List<Map<String, dynamic>>> categorizedData = {};

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Fetch data from the Google Apps Script web app
  Future<void> _fetchData() async {
    try {
      // Replace with your Google Apps Script web app URL
      final response = await http.get(Uri.parse(
          'https://script.googleusercontent.com/macros/echo?user_content_key=AehSKLhpBT_VziMgV0Hy8ole9YHCBMwp47dhjE1RXI6ow9wh-g2XCX9nh-Vf4unNZROjXatMWfM-OnoXJrpj7iCKDqvmjf-Ky1nOA4cVpYW-x32m_7rv4L7OKlh0uNUgLi-NN8HVUAxe2gO4ec_CvWriqxIxyg_G5ZVZijrJb0jWi6fp1-eWERv7p3Q18Wk7FZKgAUr360nO_fiU5ZVt-1fw5XuLyftgp-ls2i_1DtgWXH41O5D1AOG5T_x33Z1tcIlcMdYtTiA9ZXYuOLj2uyYlsl4euRrPW5RWF6W4Rcy3&lib=M6WyB417A2e40N8tJEsmGV9J0M_K-0Qm3'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          marketData = List<Map<String, dynamic>>.from(data['data']);
          _categorizeData(); // Group data by category
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load data: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  // Group data by category
  void _categorizeData() {
    categorizedData = {};
    for (var item in marketData) {
      final category = item['category'];
      if (categorizedData.containsKey(category)) {
        categorizedData[category]!.add(item);
      } else {
        categorizedData[category] = [item];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Market Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
      ),
      backgroundColor: Colors.green[50],
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            color: Colors.green[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(categories.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndex = index;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          color: _selectedIndex == index ? Colors.green[900] : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
                    : ListView.builder(
                        itemCount: getFilteredData().length,
                        itemBuilder: (context, index) {
                          final item = getFilteredData()[index];
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 4,
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: ListTile(
                              title: Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              subtitle: Text(item['price'], style: TextStyle(color: Colors.black54), overflow: TextOverflow.ellipsis),
                              trailing: Text(item['offer'], style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Get filtered data based on the selected category and search query
  List<Map<String, dynamic>> getFilteredData() {
    final selectedCategory = categories[_selectedIndex];
    final categoryData = categorizedData[selectedCategory] ?? [];
    return categoryData.where((item) => item['name'].toLowerCase().contains(_searchQuery)).toList();
  }
}