import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_icon_generator.dart';
import 'package:path_provider/path_provider.dart';

/// A simple app that generates the app icon
/// Usage: Run this file with `flutter run -t lib/utilities/generate_app_icon.dart`
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const AppIconGeneratorApp());
}

class AppIconGeneratorApp extends StatefulWidget {
  const AppIconGeneratorApp({super.key});

  @override
  State<AppIconGeneratorApp> createState() => _AppIconGeneratorAppState();
}

class _AppIconGeneratorAppState extends State<AppIconGeneratorApp> {
  String? _iconPath;
  bool _isGenerating = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateIcon();
  }

  Future<void> _generateIcon() async {
    try {
      final path = await AppIconGenerator.createBasicAppIcon();
      setState(() {
        _iconPath = path;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('App Icon Generator'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _isGenerating
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Generating app icon...'),
                  ],
                )
              : _errorMessage != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Error: $_errorMessage',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'App icon generated successfully!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Saved to: $_iconPath',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Show the generated icon
                        if (_iconPath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_iconPath!),
                              width: 150,
                              height: 150,
                            ),
                          ),
                        const SizedBox(height: 30),
                        const Text(
                          'Manual Steps:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            '1. Copy this file to your project\'s assets/images directory\n\n'
                            '2. Run "flutter pub run flutter_launcher_icons" to generate icons for all platforms\n\n'
                            '3. Rebuild your app to apply the new icons',
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
} 