import 'package:agri/pages/agrigram/homescreen.dart';
import 'package:agri/pages/agrigram/login.dart';
import 'package:agri/pages/agrigram/verify.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          
          if (user == null) {
            return LoginPage();
          } else if (!user.emailVerified) {
            return EmailVerificationScreen();
          } else {
            return HomeScreen();
          }
        }
        return Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
