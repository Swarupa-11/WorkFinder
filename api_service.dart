import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ApiService {
  // MODIFIED: Replaced the specific IPv4 address with 'localhost'.
  // NOTE: If testing on an Android Emulator, use "http://10.0.2.2:5000"
  // For a physical device on the same local network, use the PC's current local IP.
  static String baseUrl = "http://localhost:5000"; 

  // MODIFIED: Added latitude and longitude to registration data
  static Future<Map<String, dynamic>> register(Map<String, dynamic> workerData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(workerData),
    );
    print("Register response: ${response.body}");
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone.trim(), "password": password.trim()}),
    );
    print("Login response: ${response.body}");
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> uploadPost(String workerId, String text, File? image) async {
    var uri = Uri.parse('$baseUrl/upload-post');
    var request = http.MultipartRequest('POST', uri);
    request.fields['workerId'] = workerId;
    request.fields['text'] = text;

    if (image != null) {
      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
      final mimeSplit = mimeType.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print("Upload post response: ${response.body}");
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getPosts(String workerId) async {
    final response = await http.get(Uri.parse('$baseUrl/get-posts/$workerId'));
    print("Get posts response: ${response.body}");
    return jsonDecode(response.body);
  }
  
  // NEW METHOD: Worker availability status update
  static Future<Map<String, dynamic>> updateAvailability(String workerId, bool isAvailable) async {
    final response = await http.post(
      Uri.parse('$baseUrl/worker/availability'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"workerId": workerId, "isAvailable": isAvailable}),
    );
    print("Update availability response: ${response.body}");
    return jsonDecode(response.body);
  }

  // NEW METHOD: Location-based and Availability-filtered search
  static Future<Map<String, dynamic>> findWorkersByLocation({
    required String category,
    required double latitude,
    required double longitude,
    required double radius, // in km
  }) async {
    final url = Uri.parse('$baseUrl/workers/search').replace(queryParameters: {
      'category': category.trim(),
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius': radius.toString(),
    });
    
    final response = await http.get(url);
    print("Find workers by location response: ${response.body}");
    
    return jsonDecode(response.body);
  }

  // NEW METHOD: Handles the post deletion API call
  static Future<Map<String, dynamic>> deletePost(String postId, String workerId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete-post/$postId/$workerId'),
    );
    print("Delete post response: ${response.body}");
    return jsonDecode(response.body);
  }
}
