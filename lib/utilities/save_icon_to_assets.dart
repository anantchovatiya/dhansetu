import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/direct_icon_generator.dart';
import 'dart:typed_data';

/// A utility script to generate the app icon
/// 
/// Run this to see the generated app icon in the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const AppIconGeneratorApp());
}

class AppIconGeneratorApp extends StatelessWidget {
  const AppIconGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('App Icon Generator'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Center(
            child: FutureBuilder<Uint8List>(
              future: DirectIconGenerator.generateAndSaveAppIcon(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text('Generating app icon...')
                    ],
                  );
                }
                
                if (snapshot.hasError) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 20),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 20),
                      const Text('Please copy the app icon manually to assets/images/app_icon.png'),
                    ],
                  );
                }
                
                if (!snapshot.hasData) {
                  return const Text('Failed to generate icon');
                }
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(
                        snapshot.data!,
                        width: 200,
                        height: 200,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'App Icon Generated',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Instructions:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('1. Long press on the icon above and save it to your device'),
                          SizedBox(height: 8),
                          Text('2. Copy the saved image to your project\'s assets/images folder as app_icon.png'),
                          SizedBox(height: 8),
                          Text('3. Run: flutter pub run flutter_launcher_icons'),
                          SizedBox(height: 8),
                          Text('4. Rebuild your app: flutter clean && flutter build apk'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
} 