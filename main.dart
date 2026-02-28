import 'package:flutter/material.dart';
import 'screens/main_page.dart'; // Correctly points to the button-based main screen

void main() {
  runApp(const WorkNetApp());
}

class WorkNetApp extends StatelessWidget {
  const WorkNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorkNet Connect',
      // Hide the debug banner
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use a modern theme setup
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade700),
        useMaterial3: true,
        // Global style for buttons (inherited by _buildButton)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue.shade700,
          ),
        ),
      ),
      // The application starts with the MainPage, which contains the navigation buttons.
      home: const MainPage(),
    );
  }
}
