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
          // Upload the image
          final imageResponse = await ref.read(authProvider.notifier).getDioInstance().post(
            '/Images/add',
            data: {
              'File': await MultipartFile.fromFile(image.path, filename: image.name),
              'TargetId': widget.targetId,
              'LocationType': widget.locationType,
              'Name': 'upload_${image.name}',
            },
          );

          final imageId = imageResponse.data['id'];
          final imageUrl = '${Uri.base.origin}/Images/download/$imageId';

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
                    color: Colors.black.withOpacity(0.5),
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
