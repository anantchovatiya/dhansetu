import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_icon_generator.dart';
import 'package:path/path.dart' as path;

/// A utility script to generate the app icon and copy it to the assets folder
/// 
/// Run this with `flutter run -t lib/utilities/copy_icon_to_assets.dart`
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Generate the app icon to a temporary location
  print('Generating app icon...');
  final tempIconPath = await AppIconGenerator.createBasicAppIcon();
  print('Temporary icon created at: $tempIconPath');
  
  // Create the assets/images directory if it doesn't exist
  final projectDir = Directory.current.path;
  final assetsDir = Directory(path.join(projectDir, 'assets', 'images'));
  
  if (!await assetsDir.exists()) {
    await assetsDir.create(recursive: true);
    print('Created directory: ${assetsDir.path}');
  }
  
  // Target path for the icon in the assets directory
  final targetIconPath = path.join(assetsDir.path, 'app_icon.png');
  
  try {
    // Read the temporary file
    final iconBytes = await File(tempIconPath).readAsBytes();
    
    // Write to the target location
    await File(targetIconPath).writeAsBytes(iconBytes);
    
    print('✅ Successfully copied icon to: $targetIconPath');
    print('\nNext step: Run "flutter pub run flutter_launcher_icons" to generate icons for all platforms');
  } catch (e) {
    print('❌ Error copying icon: $e');
  }
  
  // Exit the application
  exit(0);
} 