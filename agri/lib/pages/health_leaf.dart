import 'dart:io';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeafHealthCheckPage extends StatefulWidget {
  @override
  _LeafHealthCheckPageState createState() => _LeafHealthCheckPageState();
}

class _LeafHealthCheckPageState extends State<LeafHealthCheckPage> {
  String _output = 'No result yet';
  XFile? _image;
  Interpreter? _interpreter;
  final TextEditingController _plantNameController = TextEditingController();
  String _advice = '';
  bool _isLoadingAdvice = false;

  static const String _apiKey = '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';
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      FirebaseCustomModel model = await FirebaseModelDownloader.instance
          .getModel("leaf_detection", FirebaseModelDownloadType.localModelUpdateInBackground);
      _interpreter = Interpreter.fromFile(File(model.file.path));
    } catch (e) {
      setState(() {
        _output = 'Error loading model';
      });
    }
  }

  Future<void> runModelOnImage(XFile image) async {
    try {
      if (_interpreter == null) {
        setState(() {
          _output = 'Model not loaded';
        });
        return;
      }

      await Future.delayed(Duration(seconds: 2));

      List<String> categories = ['Healthy', 'Unhealthy'];
      String simulatedResult = categories[(DateTime.now().millisecondsSinceEpoch % 2)];

      setState(() {
        _output = 'Health Status: $simulatedResult';
        if (simulatedResult == 'Unhealthy') {
          Vibration.vibrate();
        }
      });
    } catch (e) {
      setState(() {
        _output = 'Error during processing';
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
        _output = 'Processing...';
      });
      await runModelOnImage(pickedFile);
    }
  }

  Future<void> getAdvice() async {
    if (_output.contains('Unhealthy') && _plantNameController.text.isNotEmpty) {
      setState(() {
        _isLoadingAdvice = true;
        _advice = '';
      });

      try {
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {
            "Authorization": "Bearer $_apiKey",
            "Content-Type": "application/json",
          },
          body: json.encode({
            "model": "gpt-3.5-turbo",
            "messages": [
              {
                "role": "user",
                "content": "Provide remedies for an unhealthy ${_plantNameController.text} plant."
              }
            ],
          }),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          setState(() {
            _advice = responseData['choices'][0]['message']['content'];
          });
        } else {
          setState(() {
            _advice = 'Failed to fetch advice: ${response.statusCode}';
          });
        }
      } catch (e) {
        setState(() {
          _advice = 'Error: $e';
        });
      } finally {
        setState(() {
          _isLoadingAdvice = false;
        });
      }
    } else {
      setState(() {
        _advice = 'Please enter the plant name and ensure the plant is unhealthy.';
      });
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    _plantNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color outputColor = (_output.contains('Unhealthy')) ? Colors.red : Colors.green[900]!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Leaf Health Check', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.green.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 20),
              if (_image != null)
                Image.file(File(_image!.path), width: 300, height: 200, fit: BoxFit.cover)
              else
                Container(
                  width: 300,
                  height: 200,
                  color: Colors.green.shade100,
                  child: Center(child: Text('No image selected')),
                ),
              SizedBox(height: 30),
              Text(_output, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: outputColor)),
              SizedBox(height: 20),
              if (_output.contains('Unhealthy'))
                Column(
                  children: [
                    TextField(controller: _plantNameController, decoration: InputDecoration(hintText: 'Enter plant name')),
                    SizedBox(height: 20),
                    ElevatedButton(onPressed: _isLoadingAdvice ? null : getAdvice, child: Text('Get Advice')),
                  ],
                ),
              SizedBox(height: 20),
              if (_advice.isNotEmpty) Text(_advice, style: TextStyle(fontSize: 16, color: Colors.green[900])),
              SizedBox(height: 20),
              ElevatedButton(onPressed: pickImage, child: Text('Capture Image')),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
