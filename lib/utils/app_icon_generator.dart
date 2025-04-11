import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/app_logo.dart';

/// A class with static methods to generate app icons
class AppIconGenerator {
  /// Create a simple PNG file that can be used as an app icon
  static Future<String> createBasicAppIcon() async {
    // Set up a picture recorder to record drawing operations
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Size for the icon (1024x1024 is recommended for app stores)
    const Size size = Size(1024, 1024);
    
    // Draw a circular background
    final Paint bgPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, bgPaint);
    
    // Draw the rupee symbol
    final Paint rupeePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round;
    
    // Define the rupee symbol path
    final Path rupeePath = Path()
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
    
    canvas.drawPath(rupeePath, rupeePaint);
    
    // Draw the graph line
    final Paint graphPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round;
    
    final Path graphPath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.65)
      ..lineTo(size.width * 0.4, size.height * 0.75)
      ..lineTo(size.width * 0.6, size.height * 0.55)
      ..lineTo(size.width * 0.75, size.height * 0.65);
    
    canvas.drawPath(graphPath, graphPaint);
    
    // End recording and create an image
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.width.toInt(), size.height.toInt());
    
    // Convert to PNG
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to convert image to PNG');
    }
    
    final Uint8List pngBytes = byteData.buffer.asUint8List();
    
    // Get a directory where we can write files
    final Directory tempDir = await getTemporaryDirectory();
    final String iconFileName = 'app_icon.png';
    final String tempPath = '${tempDir.path}/$iconFileName';
    
    // Save to temporary file
    final File tempFile = File(tempPath);
    await tempFile.writeAsBytes(pngBytes);
    
    // For app usage, copy this file to your project's assets/images folder manually
    return tempPath;
  }
} 