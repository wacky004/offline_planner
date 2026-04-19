import 'dart:io';
import 'dart:math';
import '../models/registered_face.dart';

class FaceRecognitionService {
  /// Detects if an image has a face.
  /// For this offline fallback implementation, we assume any valid image contains a face.
  /// In the future, this can be swapped with `google_mlkit_face_detection`.
  Future<bool> detectFace(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) return false;
    // Mock: assume all valid images have exactly 1 face for the sake of the fallback flow
    return true;
  }

  /// Attempts to recognize the face and returns the person's ID if found.
  /// For the offline fallback, we simulate recognition by returning a random
  /// registered person's ID to demonstrate the "automatic" flow.
  Future<String?> recognizeFace(String imagePath, List<RegisteredFace> registeredFaces) async {
    // Real implementation would extract embeddings and compare via cosine similarity.
    if (registeredFaces.isEmpty) return null;
    
    // Simulate ML processing delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate match by picking a random registered face
    final random = Random();
    final match = registeredFaces[random.nextInt(registeredFaces.length)];
    return match.id;
  }
}
