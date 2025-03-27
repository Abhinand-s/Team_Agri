import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationScreen extends StatefulWidget {
  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isEmailVerified = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();
  }

  Future<void> _checkEmailVerified() async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    setState(() {
      _isEmailVerified = user?.emailVerified ?? false;
    });

    if (_isEmailVerified) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Verification email sent! Check your inbox.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify Email")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "A verification email has been sent to your email address. Please verify your email before continuing.",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            _isResending
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _resendVerificationEmail,
                    child: Text("Resend Verification Email"),
                  ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _checkEmailVerified,
              child: Text("I've Verified My Email"),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text("Back to Login"),
            ),
          ],
        ),
      ),
    );
  }
}
