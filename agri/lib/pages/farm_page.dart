
import 'package:agri/pages/agrigram/wrapper.dart';
import 'package:agri/pages/crop.dart';
import 'package:agri/pages/hardware.dart';
import 'package:agri/pages/health_leaf.dart';
import 'package:agri/pages/market.dart';
import 'package:agri/pages/qr_generator.dart';
import 'package:agri/pages/weather.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';
import 'dart:async';

class FarmerHomePage extends StatefulWidget {
  @override
  _FarmerHomePageState createState() => _FarmerHomePageState();
}

class _FarmerHomePageState extends State<FarmerHomePage> {
  final List<String> backgroundImages = [
    'assets/1.jpg',
    'assets/2.jpg',
    'assets/3.jpg',
    'assets/4.jpg',
  ];

  int _currentImageIndex = 0;
  late Timer _backgroundTimer;

  @override
  void initState() {
    super.initState();
    _startBackgroundImageRotation();
  }

  @override
  void dispose() {
    _backgroundTimer.cancel();
    super.dispose();
  }

  void _startBackgroundImageRotation() {
    _backgroundTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % backgroundImages.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'AgriHub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.withOpacity(0.7),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(seconds: 1),
            child: Container(
              key: ValueKey<String>(backgroundImages[_currentImageIndex]),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(backgroundImages[_currentImageIndex]),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.15),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 160),
            child: Column(
              children: [
                _buildWeatherCard(context),
                const SizedBox(height: 24),
                _buildCustomButton(
  context: context,
  label: 'Agri Gram',
  icon: Icons.group,
  gradientColors: [Colors.green, Colors.lightGreen],
  targetPage: AuthWrapper(), // Navigates to authentication
),

                const SizedBox(height: 16),
                _buildCustomButton(
                  context: context,
                  label: 'Qr Generator',
                  icon: Icons.qr_code,
                  gradientColors: [Colors.teal, Colors.greenAccent],
                  targetPage: QRCodeGeneratorPage(),
                ),
                const SizedBox(height: 16),
                _buildFeatureGrid(context),
              ],
            ),
          ),
        ],
      ),
    );
  }


Widget _buildWeatherCard(BuildContext context) {
  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance.collection('weather_data').doc('latest').snapshots(),
    builder: (context, snapshot) {
      String temperature = "Fetching...";
      String humidity = "Fetching...";
      String windSpeed = "Fetching...";

      if (snapshot.hasData && snapshot.data!.exists) {
        var data = snapshot.data!.data() as Map<String, dynamic>;
        temperature = "${data['temperature']?.toStringAsFixed(0) ?? "N/A"}°C";
        humidity = "${data['humidity']?.toString() ?? "N/A"}%";
        windSpeed = "${data['windSpeed']?.toString() ?? "N/A"} km/h";
      }

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WeatherDetailsPage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    temperature,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.wb_sunny, size: 50, color: Colors.amber),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Humidity: $humidity   |   Wind: $windSpeed',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    },
  );
}


  Widget _buildCustomButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required Widget targetPage,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetPage),
          );
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildFeatureTile(
          context,
          icon: Icons.memory,
          title: 'Hardware Monitoring',
          targetPage: HardwareDetailsPage(),
          color: Colors.brown[200]!,
        ),
        _buildFeatureTile(
          context,
          icon: Icons.agriculture,
          title: 'Crop & Fertilizer',
          targetPage: Croppage(),
          color: Colors.orange[200]!,
        ),
        _buildFeatureTile(
          context,
          icon: Icons.local_florist,
          title: 'Leaf Health Check',
          targetPage:LeafHealthCheckPage(),
          color: Colors.green[200]!,
        ),
        _buildFeatureTile(
          context,
          icon: Icons.cloud,
          title: 'Market Dashboard',
          targetPage: MarketDashboard(),
          color: Colors.blue[200]!,
        ),
      ],
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget targetPage,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.green[900]),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AgriGramPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agri Gram'),
        backgroundColor: Colors.green[700],
      ),
      body: const Center(
        child: Text(
          'Welcome to Agri Gram!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}



