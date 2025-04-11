import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:expense_tracker/widgets/app_logo.dart';

/// A utility class to create the app icon from our AppLogo widget.
/// 
/// Note: This cannot be run directly as it uses the dart:ui library
/// which requires a Flutter environment. The code is provided as a guide
/// to illustrate how to create an app icon from a widget.
class AppIconCreator {
  
  /// A method that demonstrates how to render the AppLogo widget to an image
  static Future<void> createAppIcon() async {
    // Create a PictureRecorder
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    
    // Set up the size
    const size = Size(1024, 1024);
    
    // Create a logo instance with a specific theme
    final logo = AppLogo(
      size: size.width,
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      accentColor: Colors.amber,
    );
    
    // We would need to build and render the widget, but this
    // cannot be done directly outside of the widget tree.
    // In a real app, you would use a RepaintBoundary and toImage() method
    
    // The following code is just a representation of what would be done
    final Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final File file = File('assets/images/app_icon.png');
      await file.writeAsBytes(pngBytes);
      print('Icon created at: ${file.path}');
    }
  }
  
  /// Instructions for creating an app icon:
  /// 
  /// 1. Create a new Flutter app with a screen that shows just the AppLogo
  /// 2. Wrap the AppLogo in a RepaintBoundary with a key
  /// 3. Use the following code to capture the widget:
  /// 
  /// ```dart
  /// RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  /// ui.Image image = await boundary.toImage(pixelRatio: 3.0);
  /// ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  /// Uint8List pngBytes = byteData!.buffer.asUint8List();
  /// 
  /// // Save to file
  /// final file = File('app_icon.png');
  /// await file.writeAsBytes(pngBytes);
  /// ```
  /// 
  /// 4. Copy the saved PNG to your assets/images folder
  static void instructions() {
    print('See the comments in the code for instructions on creating an app icon.');
  }
} 