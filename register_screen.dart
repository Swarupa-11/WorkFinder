import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // REQUIRED PACKAGE: geolocator
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final categoryController = TextEditingController();
  final addressController = TextEditingController();
  bool loading = false;
  
  // NEW: Location state variables
  double? _latitude;
  double? _longitude;
  String _locationMessage = "Tap to get your current location";

  // NEW: Location Permission and Fetching Logic
  Future<void> _getCurrentLocation() async {
    setState(() {
      loading = true;
      _locationMessage = "Getting location...";
    });

    try {
      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          setState(() {
            loading = false;
            _locationMessage = "Location permissions denied. Cannot register without location.";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission is required for worker registration.")),
          );
          return;
        }
      }

      // Fetch position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationMessage = "Location recorded: Lat ${_latitude!.toStringAsFixed(4)}, Lon ${_longitude!.toStringAsFixed(4)}";
        loading = false;
      });
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        loading = false;
        _locationMessage = "Failed to get location. Tap to retry.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    }
  }

  void register() async {
    // 1. Check for empty fields
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty ||
        categoryController.text.isEmpty ||
        addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    // 2. Check for mobile number length
    if (phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Mobile number must be 10 digits.")),
      );
      return; 
    }
    
    // NEW: Check for location
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please get your current location first.")),
      );
      return;
    }

    setState(() => loading = true);

    final workerData = {
      "name": nameController.text,
      "phone": phoneController.text.trim(),
      "password": passwordController.text.trim(),
      "category": categoryController.text.trim(),
      "address": addressController.text.trim(),
      "latitude": _latitude, // NEW: Include location
      "longitude": _longitude, // NEW: Include location
    };

    final res = await ApiService.register(workerData);
    
    setState(() => loading = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Registration successful!")),
      );
      // Optional: Navigate to login after successful registration
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Registration failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone"), keyboardType: TextInputType.phone),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: "Category: please use all small letters")),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address")),
              
              const SizedBox(height: 20),
              
              // NEW: Location button and message
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_locationMessage, style: TextStyle(color: _latitude != null ? Colors.green : Colors.black54)),
                trailing: IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: loading ? null : _getCurrentLocation,
                  color: Colors.blue,
                ),
              ),
              
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: loading ? null : register,
                child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Register"),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
