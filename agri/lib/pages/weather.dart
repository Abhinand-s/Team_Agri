import 'dart:async';
import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agri/pages/const.dart';

class WeatherDetailsPage extends StatefulWidget {
  @override
  _WeatherDetailsPageState createState() => _WeatherDetailsPageState();
}

class _WeatherDetailsPageState extends State<WeatherDetailsPage> {
  final WeatherFactory _wf = WeatherFactory(OPENWEATHER_API_KEY);
  Weather? _weather;
  String _cityName = "Enter city name";
  Timer? _timer;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadLatestCity(); // Load the last searched city from Firestore
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer when widget is disposed
    super.dispose();
  }

  /// Load the last searched city from Firestore and start auto-update
  void _loadLatestCity() async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('weather_data').doc('latest').get();
      if (doc.exists) {
        String? lastCity = doc['cityName'];
        if (lastCity != null && lastCity.isNotEmpty) {
          setState(() {
            _cityName = lastCity;
          });
          _fetchWeather(lastCity); // Fetch immediately
          _startAutoUpdate(lastCity); // Start auto-fetch every 1 min
        }
      }
    } catch (e) {
      print("❌ Error loading latest city: $e");
    }
  }

  /// Start fetching weather every 1 minute
  void _startAutoUpdate(String cityName) {
    _timer?.cancel(); // Cancel existing timer if any
    _timer = Timer.periodic(const Duration(minutes: 1), (Timer t) {
      _fetchWeather(cityName);
    });
  }

  /// Fetch weather data using OpenWeather API and update Firestore
  void _fetchWeather(String cityName) async {
    try {
      Weather w = await _wf.currentWeatherByCityName(cityName);
      setState(() {
        _weather = w;
        _cityName = cityName;
      });

      await _updateWeatherInFirestore(cityName, w);
    } catch (e) {
      print("❌ Error fetching weather: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching weather. Try again.")),
      );
    }
  }

  /// Update Firestore with new weather data (removing previous city)
  Future<void> _updateWeatherInFirestore(String cityName, Weather w) async {
    try {
      // Check if the previous city exists and delete it
      DocumentSnapshot doc = await _firestore.collection('weather_data').doc('latest').get();
      if (doc.exists) {
        await _firestore.collection('weather_data').doc('latest').delete();
      }

      // Store the latest weather data
      await _firestore.collection('weather_data').doc('latest').set({
        'cityName': cityName,
        'areaName': w.areaName ?? cityName,
        'temperature': w.temperature?.celsius ?? 0,
        'weatherDescription': w.weatherDescription ?? "",
        'tempMax': w.tempMax?.celsius ?? 0,
        'tempMin': w.tempMin?.celsius ?? 0,
        'humidity': w.humidity ?? 0,
        'windSpeed': w.windSpeed ?? 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("✅ Weather updated for: $cityName");
    } catch (e) {
      print("❌ Error updating weather in Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Details'),
        backgroundColor: Colors.green[700],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // City Input Field
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter city name',
                ),
                onSubmitted: (value) {
                  _fetchWeather(value);
                  _startAutoUpdate(value); // Restart auto-update for new city
                },
              ),
              const SizedBox(height: 20),

              // Real-time Firestore StreamBuilder
              StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('weather_data').doc('latest').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData && snapshot.data!.exists) {
                    var data = snapshot.data!.data() as Map<String, dynamic>;
                    return Column(
                      children: [
                        Text(
                          data['areaName'] ?? "",
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${data['temperature']?.toStringAsFixed(0) ?? ""}°C",
                          style: const TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          data['weatherDescription'] ?? "",
                          style: const TextStyle(
                              fontSize: 18, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 10),
                        _extraInfo(data),
                      ],
                    );
                  } else {
                    return const Center(child: Text("No data available."));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build extra info widget
  Widget _extraInfo(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            "Max: ${data['tempMax']?.toStringAsFixed(0) ?? ""}°C  |  Min: ${data['tempMin']?.toStringAsFixed(0) ?? ""}°C",
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            "Wind: ${data['windSpeed']?.toStringAsFixed(0) ?? ""} m/s  |  Humidity: ${data['humidity']?.toStringAsFixed(0) ?? ""}%",
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
