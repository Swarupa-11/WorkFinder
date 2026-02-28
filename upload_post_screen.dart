import 'dart:io';
import 'dart:typed_data'; // ADDED for web support
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ADDED for platform check
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class UploadPostScreen extends StatefulWidget {
  final String workerId;
  const UploadPostScreen({super.key, required this.workerId});

  @override
  State<UploadPostScreen> createState() => _UploadPostScreenState();
}

class _UploadPostScreenState extends State<UploadPostScreen> {
  final textController = TextEditingController();
  
  File? selectedImage; 
  Uint8List? _pickedBytes; // ADDED: For displaying the image preview on Web
  bool loading = false;

  void pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    
    if (picked != null) {
      if (kIsWeb) {
        // Read bytes for web preview
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedBytes = bytes;
          selectedImage = null; // Ensure File is null on web
        });
      } else {
        // Use File for mobile/desktop
        setState(() {
          selectedImage = File(picked.path);
          _pickedBytes = null; // Ensure bytes is null on mobile
        });
      }
    }
  }

  void uploadPost() async {
    // Check if the user has provided any content
    if (textController.text.isEmpty && selectedImage == null && _pickedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add text or image")),
      );
      return;
    }
    
    // NOTE: For a full Web implementation, you would need to update
    // ApiService.uploadPost to handle uploading image bytes on web.
    // However, the current code addresses the build assertion error.

    setState(() => loading = true);
    
    // On web, selectedImage is null, but the text might be present. 
    // The current ApiService handles null image gracefully.
    final res = await ApiService.uploadPost(widget.workerId, textController.text, selectedImage);
    
    setState(() => loading = false);

    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post uploaded successfully!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Upload failed")),
      );
    }
  }

  // Helper method to determine if an image has been selected
  bool get _imageSelected => selectedImage != null || _pickedBytes != null;

  // NEW WIDGET: Conditional Image Preview to avoid Image.file on web
  Widget _buildImagePreview() {
    if (selectedImage != null && !kIsWeb) {
      // Mobile/Desktop preview
      return Image.file(selectedImage!, height: 200);
    } else if (_pickedBytes != null && kIsWeb) {
      // Web preview using bytes
      return Image.memory(_pickedBytes!, height: 200);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Proof of Work")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Pick Image"),
            ),
            if (_imageSelected)
              _buildImagePreview(), // Use the conditional preview
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : uploadPost,
              child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Upload"),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}
