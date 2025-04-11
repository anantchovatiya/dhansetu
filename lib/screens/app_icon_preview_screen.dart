import 'package:flutter/material.dart';
import '../utils/direct_icon_generator.dart';
import '../widgets/app_logo.dart';

class AppIconPreviewScreen extends StatelessWidget {
  const AppIconPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Icon Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About App Icons'),
                  content: const SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'The app icon is used on the home screen, in app stores, and other places.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'This icon uses the Rupee symbol (₹) to match the app\'s focus on expense tracking in Indian Rupees.',
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CLOSE'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Current App Icon',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Generated icon preview
              DirectIconGenerator.buildAppIconPreview(),
              const SizedBox(height: 40),
              
              // Show how the icon looks in different contexts
              const Text(
                'How it looks on your device',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Homescreen icon simulation
              Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAppIconSimulation(
                          icon: const Icon(Icons.message, color: Colors.white),
                          label: 'Messages',
                        ),
                        _buildAppIconSimulation(
                          icon: const Icon(Icons.call, color: Colors.white),
                          label: 'Phone',
                        ),
                        _buildAppIconSimulation(
                          icon: const AppLogo(size: 48),
                          label: 'Expenses',
                          isHighlighted: true,
                        ),
                        _buildAppIconSimulation(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          label: 'Camera',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 5,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(10),
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
  
  Widget _buildAppIconSimulation({
    required Widget icon,
    required String label,
    bool isHighlighted = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: isHighlighted 
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                )
              : null,
          child: icon,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isHighlighted ? Colors.white : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
} 