/// This file provides a reusable image upload widget.
/// 
/// It can be used throughout the app for uploading images to different entities
/// like user profiles, builds, forum posts, etc.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/utils/user_image_utils.dart';

/// A reusable widget for uploading images.
/// 
/// This widget provides a consistent interface for image uploads across the app.
/// It handles image picking, uploading, and displays appropriate loading states.
class ImageUploadWidget extends ConsumerStatefulWidget {
  /// The target ID for the image (e.g., user ID, build ID, etc.)
  final String targetId;
  
  /// The location type for the image (USER, BUILD, FORUM, etc.)
  final String locationType;
  
  /// The current image URL to display
  final String? currentImageUrl;
  
  /// The size of the image display
  final double size;
  
  /// Whether to show the upload button
  final bool showUploadButton;
  
  /// Callback when image is successfully uploaded
  final void Function(String imageUrl)? onImageUploaded;
  
  /// Callback when upload fails
  final void Function(String error)? onUploadFailed;

  const ImageUploadWidget({
    super.key,
    required this.targetId,
    required this.locationType,
    this.currentImageUrl,
    this.size = 100,
    this.showUploadButton = true,
    this.onImageUploaded,
    this.onUploadFailed,
  });

  @override
  ConsumerState<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends ConsumerState<ImageUploadWidget> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    if (_isUploading) return;

    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isUploading = true;
        });

        try {
          // Read file bytes (works for both web and mobile)
          final fileBytes = await image.readAsBytes();
          
          // Get file name
          var fileName = image.name;
          if (fileName.isEmpty || !fileName.contains('.')) {
            fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
          }
          
          // Create FormData
          final formData = FormData.fromMap({
            'File': MultipartFile.fromBytes(
              fileBytes,
              filename: fileName,
            ),
            'TargetId': widget.targetId,
            'LocationType': widget.locationType,
            'Name': 'upload_${DateTime.now().millisecondsSinceEpoch}',
          });
          
          // Upload the image
          final dio = ref.read(authProvider.notifier).getDioInstance();
          final imageResponse = await dio.post(
            '/Images/add',
            data: formData,
          );

          final imageId = imageResponse.data['id'] ?? imageResponse.data['Id'];
          final apiBaseUrl = dio.options.baseUrl;
          final imageUrl = '$apiBaseUrl/Images/download/$imageId';

          if (mounted) {
            widget.onImageUploaded?.call(imageUrl);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image uploaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            final errorMessage = e.toString();
            widget.onUploadFailed?.call(errorMessage);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload failed: $errorMessage'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isUploading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        widget.onUploadFailed?.call(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            UserImageUtils.buildUserImage(
              imageUrl: widget.currentImageUrl,
              width: widget.size,
              height: widget.size,
              borderRadius: BorderRadius.circular(widget.size / 2),
            ),
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(widget.size / 2),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (widget.showUploadButton) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickAndUploadImage,
            icon: _isUploading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload),
            label: Text(_isUploading ? 'Uploading...' : 'Upload Image'),
          ),
        ],
      ],
    );
  }
}
