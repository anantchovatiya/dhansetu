import 'package:flutter/material.dart';

/// Instructions for updating app icons:
/// 
/// 1. Add the flutter_launcher_icons package to dev_dependencies in pubspec.yaml:
///    ```yaml
///    dev_dependencies:
///      flutter_launcher_icons: ^0.13.1
///    ```
///
/// 2. Add the following configuration to pubspec.yaml:
///    ```yaml
///    flutter_launcher_icons:
///      android: "launcher_icon"
///      ios: true
///      image_path: "assets/images/app_icon.png"
///      min_sdk_android: 21
///      web:
///        generate: true
///        image_path: "assets/images/app_icon.png"
///      windows:
///        generate: true
///        image_path: "assets/images/app_icon.png"
///        icon_size: 48
///      macos:
///        generate: true
///        image_path: "assets/images/app_icon.png"
///    ```
///
/// 3. Run the following command to generate icons:
///    ```
///    flutter pub get
///    flutter pub run flutter_launcher_icons
///    ```
/// 
/// Note: This requires creating a PNG image file at assets/images/app_icon.png
/// You can create this file using the AppLogo widget and exporting it as a PNG.
class IconLauncherHelper {
  
  /// Steps to manually create the app_icon.png:
  /// 
  /// 1. Create a new Flutter project with a single screen
  /// 2. Add the following code to the main.dart file:
  /// 
  /// ```dart
  /// import 'package:flutter/material.dart';
  /// import 'package:expense_tracker/widgets/app_logo.dart';
  /// import 'package:path_provider/path_provider.dart';
  /// import 'dart:io';
  /// import 'dart:typed_data';
  /// import 'dart:ui' as ui;
  /// 
  /// void main() {
  ///   runApp(const MyApp());
  /// }
  /// 
  /// class MyApp extends StatelessWidget {
  ///   const MyApp({super.key});
  /// 
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return MaterialApp(
  ///       home: Scaffold(
  ///         backgroundColor: Colors.transparent,
  ///         body: Center(
  ///           child: Column(
  ///             mainAxisAlignment: MainAxisAlignment.center,
  ///             children: [
  ///               const AppLogo(size: 1024),
  ///               const SizedBox(height: 20),
  ///               ElevatedButton(
  ///                 onPressed: () => _captureAndSaveLogo(context),
  ///                 child: const Text('Capture Logo'),
  ///               ),
  ///             ],
  ///           ),
  ///         ),
  ///       ),
  ///     );
  ///   }
  /// 
  ///   Future<void> _captureAndSaveLogo(BuildContext context) async {
  ///     final RenderRepaintBoundary boundary = context.findRenderObject() as RenderRepaintBoundary;
  ///     final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
  ///     final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  ///     final Uint8List pngBytes = byteData!.buffer.asUint8List();
  ///     
  ///     final directory = await getApplicationDocumentsDirectory();
  ///     final file = File('${directory.path}/app_icon.png');
  ///     await file.writeAsBytes(pngBytes);
  ///     
  ///     print('Logo saved to: ${file.path}');
  ///   }
  /// }
  /// ```
  /// 
  /// 3. Run the app and press the 'Capture Logo' button
  /// 4. Copy the PNG file to your project's assets/images directory
  static void help() {
    // This method exists just to provide documentation
    print('See class documentation for instructions on updating app icons');
  }
} 