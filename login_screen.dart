import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'profile_screen.dart'; // Import ProfileScreen
import 'package:shared_preferences/shared_preferences.dart'; // Assuming you want to keep shared preferences

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); // Added const constructor
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  void login() async {
    // 1. Validation
    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final response = await ApiService.login(phoneController.text, passwordController.text);
      
      setState(() => loading = false);

      if (response['success'] == true && response['worker'] != null) {
        // Successfully logged in
        final workerData = response['worker'] as Map<String, dynamic>;

        // Store login state (e.g., phone number)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('phone', workerData['phone']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Successful')),
        );

        // 2. CRUCIAL FIX: Navigate to ProfileScreen and pass the required workerData
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(workerData: workerData)),
        );
      } else {
        // Login failed (API returned failure)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Login failed. Check phone and password.')),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      // Handle network or exception errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Worker Login"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🔐 Worker Login', 
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: phoneController, 
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),

              TextField(
                controller: passwordController, 
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ), 
                obscureText: true,
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: loading ? null : login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                ),
                child: loading 
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      ) 
                    : const Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
