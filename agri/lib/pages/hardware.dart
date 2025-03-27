import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HardwareDetailsPage extends StatefulWidget {
  @override
  _HardwareDetailsPageState createState() => _HardwareDetailsPageState();
}

class _HardwareDetailsPageState extends State<HardwareDetailsPage> {
  // Firebase Realtime Database reference
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('sensorReadings/currentData');

  // Map to store sensor data
  Map<String, dynamic> sensorData = {};

  // Track the selected sensor
  String? selectedSensor;

  // Track the latest value of the selected sensor
  double? latestValue;

  @override
  void initState() {
    super.initState();
    _fetchSensorData();
  }

  // Fetch sensor data from Firebase
  void _fetchSensorData() {
    _databaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          sensorData = Map<String, dynamic>.from(data);
        });
      }
    });
  }

  // Function to delete a sensor (optional, if needed)
  void deleteSensor(String title) {
    setState(() {
      sensorData.remove(title);
      if (selectedSensor == title) {
        selectedSensor = null; // Deselect if the deleted sensor was selected
      }
    });
  }

  // Function to handle sensor selection
  void selectSensor(String title) {
    setState(() {
      if (selectedSensor == title) {
        selectedSensor = null; // Deselect if the same sensor is tapped again
      } else {
        selectedSensor = title; // Select the tapped sensor
      }
      latestValue = null; // Reset the latest value when a new sensor is selected
    });
  }

  // Function to fetch the latest value of the selected sensor
  void _fetchLatestValue() {
    if (selectedSensor != null) {
      _databaseRef.child(selectedSensor!).onValue.listen((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && data['value'] != null) {
          // Convert the value to double (handle both String and double cases)
          double value = data['value'] is String
              ? double.tryParse(data['value']) ?? 0.0
              : data['value'].toDouble();
          setState(() {
            latestValue = value;
          });
        }
      });
    }
  }

  // Function to handle the Connect button press
  void _handleConnect() {
    if (selectedSensor != null) {
      final sensorStatus = sensorData[selectedSensor!]?['status'] ?? false;

      if (sensorStatus == true) {
        _fetchLatestValue(); // Fetch the latest value if status is true
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to $selectedSensor'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot connect: $selectedSensor is inactive'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green[50]!, Colors.lightGreen[100]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Sensor Data Cards
              Expanded(
                child: ListView(
                  children: sensorData.entries.map((entry) {
                    return _buildSensorCard(entry.key, entry.value);
                  }).toList(),
                ),
              ),
              // Connect Button (Conditional)
              if (selectedSensor != null) _buildConnectButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Build a sensor card with Agri Green Theme
  Widget _buildSensorCard(String title, dynamic value) {
    // Extract the 'value' from the sensor data and ensure it's a double
    double sensorValue = value['value'] is String
        ? double.tryParse(value['value']) ?? 0.0
        : value['value'].toDouble();

    return GestureDetector(
      onTap: () {
        selectSensor(title);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selectedSensor == title ? Colors.green[100] : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selectedSensor == title ? Colors.green[700]! : Colors.transparent,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                  Icon(
                    _getSensorIcon(title),
                    color: Colors.green[700],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${latestValue != null && selectedSensor == title ? latestValue!.toStringAsFixed(2) : sensorValue.toStringAsFixed(2)} ${_getSensorUnit(title)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Connect Button
  Widget _buildConnectButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleConnect, // Use the new _handleConnect function
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'Connect',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Get sensor icon based on title
  IconData _getSensorIcon(String title) {
    switch (title) {
      case 'soilMoisture':
        return Icons.opacity;
      case 'temperature':
        return Icons.thermostat;
      case 'airHumidity':
        return Icons.water_damage;
      case 'lightIntensity':
        return Icons.wb_sunny;
      case 'pH':
        return Icons.science;
      case 'co2':
        return Icons.cloud;
      case 'npk':
        return Icons.eco;
      case 'soilTemp':
        return Icons.thermostat;
      case 'ec':
        return Icons.electrical_services;
      case 'TDS':
        return Icons.water;
      default:
        return Icons.device_unknown;
    }
  }

  // Get sensor unit based on title
  String _getSensorUnit(String title) {
    switch (title) {
      case 'soilMoisture':
        return '%';
      case 'temperature':
        return '°C';
      case 'airHumidity':
        return '%';
      case 'lightIntensity':
        return 'lux';
      case 'pH':
        return '';
      case 'co2':
        return 'ppm';
      case 'npk':
        return '';
      case 'soilTemp':
        return '°C';
      case 'ec':
        return 'µS/cm';
      case 'TDS':
        return 'ppm';
      default:
        return '';
    }
  }
}