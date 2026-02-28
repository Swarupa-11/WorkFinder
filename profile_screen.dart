import 'package:flutter/material.dart';
import 'upload_post_screen.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> workerData;
  const ProfileScreen({super.key, required this.workerData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<dynamic>> _postsFuture;
  late bool _isAvailable; // NEW: State for availability

  @override
  void initState() {
    super.initState();
    // Initialize availability from workerData, default to false if null/missing
    _isAvailable = widget.workerData['isAvailable'] ?? false;
    _postsFuture = _fetchPosts();
  }

  Future<List<dynamic>> _fetchPosts() async {
    final workerId = widget.workerData['_id'];
    try {
      final response = await ApiService.getPosts(workerId);
      if (response['success'] == true && response['posts'] is List) {
        return response['posts'].cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print("Error fetching posts: $e");
      return [];
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _postsFuture = _fetchPosts();
    });
  }

  // NEW METHOD: Handles availability status update
  Future<void> _toggleAvailability(bool newValue) async {
    setState(() {
      _isAvailable = newValue; // Optimistic update
    });

    try {
      final workerId = widget.workerData['_id'];
      final res = await ApiService.updateAvailability(workerId, newValue);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status updated to: ${newValue ? 'Available' : 'Not Available'}")),
        );
      } else {
        // Revert on failure
        setState(() {
          _isAvailable = !newValue;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Failed to update status")),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isAvailable = !newValue;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error during status update")),
      );
    }
  }

  // NEW METHOD: Handles the post deletion logic
  Future<void> _deletePost(String postId) async {
    final workerId = widget.workerData['_id'];
    try {
      final response = await ApiService.deletePost(postId, workerId);
      if (response['success'] == true) {
        // If delete is successful, refresh the list of posts
        _refreshPosts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Post deleted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to delete post.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting post.')),
      );
      print("Error deleting post: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Assuming this navigates back to the main page/login screen
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Worker: ${widget.workerData['name']}",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text("Category: ${widget.workerData['category']}"),
                  Text("Phone: ${widget.workerData['phone']}"),
                  const Divider(),
                  
                  // NEW: Availability Toggle UI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Availability Status",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Switch(
                        value: _isAvailable,
                        onChanged: _toggleAvailability,
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                      ),
                      Text(_isAvailable ? "Available" : "Not Available", 
                           style: TextStyle(color: _isAvailable ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "My Proof of Works",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UploadPostScreen(workerId: widget.workerData['_id']),
                            ),
                          ).then((_) => _refreshPosts()); // Refresh when returning
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("New Post"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Post list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FutureBuilder<List<dynamic>>(
                  future: _postsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No posts uploaded yet."));
                    } else {
                      final posts = snapshot.data!;
                      return ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          final imagePath = post['image'];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 15),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          post['text'] ?? 'No Description',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deletePost(post['_id']),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  if (imagePath != null && imagePath.isNotEmpty)
                                    Image.network(
                                      // Use ApiService.baseUrl for the image URL
                                      "${ApiService.baseUrl}/$imagePath", 
                                      height: 250, 
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(child: Text("Image failed to load (Check Server path)"));
                                      },
                                    ),
                                    
                                  if (imagePath != null && imagePath.isNotEmpty) 
                                    const SizedBox(height: 10),

                                  Text(
                                    "Posted: ${DateTime.parse(post['createdAt']).toLocal().toString().split(' ')[0]}", 
                                    style: const TextStyle(color: Colors.grey, fontSize: 12)
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
