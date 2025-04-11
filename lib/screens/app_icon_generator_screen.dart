import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/app_logo.dart';

/// A screen that allows you to generate and save an app icon 
/// from the AppLogo widget
class AppIconGeneratorScreen extends StatefulWidget {
  const AppIconGeneratorScreen({super.key});

  @override
  State<AppIconGeneratorScreen> createState() => _AppIconGeneratorScreenState();
}

class _AppIconGeneratorScreenState extends State<AppIconGeneratorScreen> {
  final GlobalKey _logoKey = GlobalKey();
  String? _savePath;
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Icon Generator'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'App Logo Preview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              // Logo wrapped in RepaintBoundary for capturing
              RepaintBoundary(
                key: _logoKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: const AppLogo(size: 300),
                ),
              ),
              const SizedBox(height: 32),
              _generating
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _captureAndSaveIcon,
                      child: const Text('Generate App Icon'),
                    ),
              const SizedBox(height: 16),
              if (_savePath != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Icon saved successfully!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _savePath!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      if (_savePath != null) 
                        Column(
                          children: [
                            const Text('Icon Preview:'),
                            const SizedBox(height: 8),
                            Image.file(
                              File(_savePath!),
                              width: 100,
                              height: 100,
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Copy this file to your assets/images folder, then run:',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'flutter pub run flutter_launcher_icons',
                          style: TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureAndSaveIcon() async {
    setState(() {
      _generating = true;
    });

    try {
      // Get the RenderRepaintBoundary from the key
      RenderRepaintBoundary boundary = _logoKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // Capture the image with high quality
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      
      // Convert to PNG bytes
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to PNG');
      }
      
      Uint8List pngBytes = byteData.buffer.asUint8List();
      
      // Get a directory where we can write files
      final Directory tempDir = await getTemporaryDirectory();
      final String iconFileName = 'app_icon.png';
      final String tempPath = '${tempDir.path}/$iconFileName';
      
      // Save to temporary file
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(pngBytes);
      
      setState(() {
        _savePath = tempPath;
        _generating = false;
      });
    } catch (e) {
      setState(() {
        _generating = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 