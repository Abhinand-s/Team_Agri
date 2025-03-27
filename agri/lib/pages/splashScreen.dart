import 'package:agri/pages/getstart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import the package

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the home page after a delay
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => FarmerPage()), // Change to your home page
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.userGroup, // Farmer-related icon
              size: 100, // Adjust size as needed
              color: Colors.green[800], // Green color for the icon
            ),
            SizedBox(height: 20),
            Text(
              'Agri', // App name
              style: TextStyle(
                fontSize: 48, // Adjust size as needed
                fontWeight: FontWeight.bold,
                color: Colors.green[800], // Bold green letters
              ),
            ),
            SizedBox(height: 10),
            Text(
              'A solution for farmers', // Subtitle
              style: TextStyle(
                fontSize: 20, // Adjust size as needed
                color: Colors.green[600], // Color for subtitle
              ),
            ),
            SizedBox(height: 20), // Space between subtitle and progress indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[800]!),
            ),
          ],
        ),
      ),
    );
  }
}
