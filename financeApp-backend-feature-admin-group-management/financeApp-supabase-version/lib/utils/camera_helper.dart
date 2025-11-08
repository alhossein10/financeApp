import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CameraHelper {
  static Future<String?> takePicture(BuildContext context) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No camera available')),
          );
        }
        return null;
      }

      final camera = cameras.first;
      final result = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(camera: camera),
        ),
      );

      if (result != null) {
        // Process and enhance the image for document scanning
        final processedPath = await _enhanceDocument(result.path);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo saved successfully')),
          );
        }

        return processedPath;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    return null;
  }

  // Enhance image for better document readability
  static Future<String> _enhanceDocument(String imagePath) async {
    try {
      // Read the image
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image != null) {
        // Apply document enhancement filters
        var enhanced = image;
        
        // 1. Increase contrast for better text visibility
        enhanced = img.adjustColor(enhanced, contrast: 1.3);
        
        // 2. Increase brightness slightly
        enhanced = img.adjustColor(enhanced, brightness: 1.1);
        
        // 3. Sharpen the image for clearer text
        enhanced = img.convolution(enhanced, 
          filter: [
            0, -1, 0,
            -1, 5, -1,
            0, -1, 0
          ],
          div: 1,
          offset: 0,
        );

        // Save enhanced image
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = '${appDir.path}/$fileName';
        
        final enhancedBytes = img.encodeJpg(enhanced, quality: 90);
        await File(savedPath).writeAsBytes(enhancedBytes);
        
        return savedPath;
      }
    } catch (e) {
      // If enhancement fails, just save the original
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${appDir.path}/$fileName';
      await File(imagePath).copy(savedPath);
      return savedPath;
    }

    // Fallback: save original
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = '${appDir.path}/$fileName';
    await File(imagePath).copy(savedPath);
    return savedPath;
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take Photo')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            if (context.mounted) {
              Navigator.pop(context, image);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
