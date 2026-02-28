import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'login_screen.dart';
import 'find_worker_screen.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WorkNet Connect"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Welcome to WorkNet Connect",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Connect with skilled workers or register your services.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            _buildButton(
              context,
              "📝 Register as a Worker",
              const RegisterScreen(),
            ),
            const SizedBox(height: 20),
            _buildButton(
              context,
              "🔐 Worker Login",
              const LoginScreen(),
            ),
            const SizedBox(height: 20),
            _buildButton(
              context,
              "🔎 Find Worker Near Me",
              const FindWorkerScreen(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function for consistent button styling and navigation logic
  Widget _buildButton(BuildContext context, String text, Widget screen) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      style: ElevatedButton.styleFrom(
        // Set minimum size for better touch target
        minimumSize: const Size.fromHeight(50), 
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(text),
    );
  }
}
