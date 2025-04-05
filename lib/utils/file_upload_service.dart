import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class FileUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final _uuid = const Uuid();

  // Pick multiple images from gallery
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 70,
      );

      if (pickedFiles.isNotEmpty) {
        return pickedFiles.map((xFile) => File(xFile.path)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error picking images: $e');
      return [];
    }
  }

  // Pick a single image from gallery
  Future<File?> pickSingleImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Upload a single file to Firebase Storage
  Future<String?> uploadFile(File file, String folder) async {
    try {
      String fileName = '${_uuid.v4()}${path.extension(file.path)}';
      Reference storageRef = _storage.ref().child('$folder/$fileName');

      UploadTask uploadTask = storageRef.putFile(file);

      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  // Upload multiple files to Firebase Storage
  Future<List<String>> uploadMultipleFiles(
    List<File> files,
    String folder,
  ) async {
    try {
      List<String> downloadUrls = [];

      for (final file in files) {
        final url = await uploadFile(file, folder);
        if (url != null) {
          downloadUrls.add(url);
        }
      }

      return downloadUrls;
    } catch (e) {
      debugPrint('Error uploading multiple files: $e');
      return [];
    }
  }

  // Delete a file from Firebase Storage by URL
  Future<bool> deleteFile(String fileUrl) async {
    try {
      Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }
}
