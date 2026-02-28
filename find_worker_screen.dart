import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // REQUIRED PACKAGE: geolocator
import '../services/api_service.dart';

class FindWorkerScreen extends StatefulWidget {
  const FindWorkerScreen({super.key});

  @override
  State<FindWorkerScreen> createState() => _FindWorkerScreenState();
}

class _FindWorkerScreenState extends State<FindWorkerScreen> {
  final categoryController = TextEditingController();
  List<dynamic> workers = [];
  bool loading = false;
  String message = "Enter category, select radius, and get location to search.";
  
  // NEW: Location and Radius state
  double _radius = 5.0; // Default radius 5km
  double? _latitude;
  double? _longitude;
  String _locationMessage = "Get your location for search";

  @override
  void initState() {
    super.initState();
    // Pre-load location as soon as the screen opens
    _getCurrentLocation(); 
  }
  
  // NEW: Location Permission and Fetching Logic for Workfinder
  Future<void> _getCurrentLocation() async {
    setState(() {
      loading = true;
      _locationMessage = "Getting location...";
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          setState(() {
            loading = false;
            _locationMessage = "Location permissions denied. Cannot perform proximity search.";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission is required for proximity search.")),
          );
          return;
        }
      }

      // Fetch position (using low accuracy as high accuracy is generally not needed for search)
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationMessage = "Search location set: Lat ${_latitude!.toStringAsFixed(4)}, Lon ${_longitude!.toStringAsFixed(4)}";
        loading = false;
      });
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        loading = false;
        _locationMessage = "Failed to get location. Try again.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    }
  }

  // MODIFIED: Search logic to include location and radius
  void searchWorkers() async {
    final category = categoryController.text.trim();
    if (category.isEmpty) {
      setState(() {
        workers = [];
        message = "Please enter a category.";
      });
      return;
    }
    
    if (_latitude == null || _longitude == null) {
       setState(() {
        workers = [];
        message = "Please get your current location first.";
      });
      return;
    }

    setState(() {
      loading = true;
      workers = [];
      message = "Searching...";
    });

    try {
      // Call the new proximity search API
      final res = await ApiService.findWorkersByLocation(
        category: category,
        latitude: _latitude!,
        longitude: _longitude!,
        radius: _radius,
      );
      
      if (res['success'] == true && res['workers'] is List) {
        setState(() {
          workers = res['workers'];
          message = workers.isEmpty 
              ? "No AVAILABLE workers found in '$category' within ${_radius.toStringAsFixed(0)}km." 
              : "${workers.length} AVAILABLE workers found.";
        });
      } else {
        setState(() {
          workers = [];
          message = res['message'] ?? "Search failed. Try again.";
        });
      }
    } catch (e) {
      print("Search error: $e");
      setState(() {
        loading = false;
        message = "An error occurred during search. Check server connection.";
      });
    }
  }

  @override
  void dispose() {
    categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find Workers Near Me")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Category Input
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Worker Category (e.g. plumber, electrician)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Location Info & Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(_locationMessage, style: TextStyle(color: _latitude != null ? Colors.green : Colors.black54)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: loading ? null : _getCurrentLocation,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Radius Slider (5km to 20km)
            Row(
              children: [
                const Text("Search Radius: "),
                Expanded(
                  child: Slider(
                    value: _radius,
                    min: 5,
                    max: 20,
                    divisions: 15, // 5, 6, 7, ..., 20
                    label: '${_radius.round()} km',
                    onChanged: (double value) {
                      setState(() {
                        _radius = value;
                      });
                    },
                  ),
                ),
                Text('${_radius.round()} km', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            
            // Search Button
            ElevatedButton(
              onPressed: loading ? null : searchWorkers,
              child: loading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text("Search Available Workers"),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
            
            const SizedBox(height: 20),
            
            // Results Section
            Expanded(
              child: Builder(
                builder: (context) {
                  if (loading && workers.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (workers.isEmpty) {
                    return Center(child: Text(message));
                  }
                  
                  return ListView.builder(
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      final worker = workers[index];
                      // Use the latest post for display if available
                      final lastPost = worker['posts'] != null && worker['posts'].isNotEmpty 
                          ? worker['posts'][0] 
                          : null;
                          
                      final imagePath = lastPost?['image'];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                worker['name'] ?? 'No Name',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                              const Divider(height: 10),
                              Text("Category: ${worker['category']}"),
                              Text("Phone: ${worker['phone']}"),
                              // Availability Status (should always be Available based on search criteria)
                              Row(
                                children: [
                                  const Text("Status: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    worker['isAvailable'] == true ? "Available" : "Not Available",
                                    style: TextStyle(color: worker['isAvailable'] == true ? Colors.green : Colors.red),
                                  ),
                                ],
                              ),
                              
                              if (lastPost != null) ...[
                                const SizedBox(height: 10),
                                const Text("Latest Work Post:", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  lastPost['text'] ?? 'No Description',
                                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                                ),
                                if (imagePath != null && imagePath.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        "${ApiService.baseUrl}/$imagePath", 
                                        height: 150, 
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(child: Text("Image failed to load"));
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                              const SizedBox(height: 5),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
