import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_logo.dart';

/// A utility to generate and save app icons directly with proper permissions
class DirectIconGenerator {
  
  /// Generates an app icon and returns it as a Uint8List
  static Future<Uint8List> generateAndSaveAppIcon() async {
    // Set up canvas and paint
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Icon dimensions (1024x1024 recommended for app stores)
    const size = Size(1024, 1024);
    
    // Draw background
    final bgPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, bgPaint);
    
    // Draw rupee symbol
    final symbolPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round;
    
    // Define rupee symbol path
    final rupeePath = Path()
      // Horizontal line at top
      ..moveTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      
      // Vertical line
      ..moveTo(size.width * 0.5, size.height * 0.3)
      ..lineTo(size.width * 0.5, size.height * 0.75)
      
      // Middle horizontal line
      ..moveTo(size.width * 0.3, size.height * 0.45)
      ..lineTo(size.width * 0.7, size.height * 0.45)
      
      // Diagonal line
      ..moveTo(size.width * 0.3, size.height * 0.45)
      ..lineTo(size.width * 0.7, size.height * 0.75);
    
    canvas.drawPath(rupeePath, symbolPaint);
    
    // Draw graph line
    final graphPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round;
    
    final graphPath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.65)
      ..lineTo(size.width * 0.4, size.height * 0.75)
      ..lineTo(size.width * 0.6, size.height * 0.55)
      ..lineTo(size.width * 0.75, size.height * 0.65);
    
    canvas.drawPath(graphPath, graphPaint);
    
    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
      throw Exception('Failed to convert image to PNG');
    }
    
    final pngBytes = byteData.buffer.asUint8List();
    
    // Return the PNG bytes
    return pngBytes;
  }
  
  /// Creates a widget that displays the generated icon
  static Widget buildAppIconPreview() {
    return FutureBuilder<Uint8List>(
      future: generateAndSaveAppIcon(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        
        if (!snapshot.hasData) {
          return const Text('No image data');
        }
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                snapshot.data!,
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This is how your app icon will look',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }
} 