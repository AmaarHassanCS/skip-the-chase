import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<String> uploadProfileImage(String userId, String filePath) async {
    try {
      final fileExtension = path.extension(filePath);
      final fileName = '${_uuid.v4()}$fileExtension';
      
      await _supabase.storage
          .from('profile_images')
          .upload('$userId/$fileName', File(filePath));
      
      final imageUrl = _supabase.storage
          .from('profile_images')
          .getPublicUrl('$userId/$fileName');
      
      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  Future<List<String>> uploadProfileImages(String userId, List<String> filePaths) async {
    try {
      final urls = <String>[];
      
      for (final filePath in filePaths) {
        final url = await uploadProfileImage(userId, filePath);
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      throw Exception('Failed to upload profile images: $e');
    }
  }

  Future<void> deleteProfileImage(String userId, String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.last;
      
      await _supabase.storage
          .from('profile_images')
          .remove(['$userId/$fileName']);
    } catch (e) {
      throw Exception('Failed to delete profile image: $e');
    }
  }
}