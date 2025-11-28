/// This file provides an authenticated image widget that uses Dio to load images
/// with proper authorization headers, solving the 403 Forbidden issue.
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/utils/user_image_utils.dart';

/// A widget that loads images using authenticated Dio requests.
/// This solves the 403 Forbidden issue when loading user profile images.
class AuthenticatedImage extends ConsumerStatefulWidget {
  /// The image URL or GUID to load
  final String? imageUrl;
  
  /// Widget to show while loading
  final Widget? placeholder;
  
  /// Widget to show on error
  final Widget? errorWidget;
  
  /// Width of the image
  final double? width;
  
  /// Height of the image
  final double? height;
  
  /// How to fit the image
  final BoxFit fit;
  
  /// Border radius for the image
  final BorderRadius? borderRadius;
  
  /// Whether this is a circular avatar
  final bool isCircle;
  
  /// Radius for circular avatar
  final double? radius;
  
  /// Background color for avatar
  final Color? backgroundColor;
  
  /// Username for fallback avatar
  final String? username;
  
  /// User ID for fallback avatar
  final String? userId;

  const AuthenticatedImage({
    super.key,
    required this.imageUrl,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isCircle = false,
    this.radius,
    this.backgroundColor,
    this.username,
    this.userId,
  });

  @override
  ConsumerState<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends ConsumerState<AuthenticatedImage> {
  Uint8List? _imageBytes;
  String? _cachedUrl;
  bool _isLoading = false;
  bool _hasError = false;

  Future<void> _loadImage(String url) async {
    if (_cachedUrl == url && _imageBytes != null) {
      return; // Already loaded
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final dio = ref.read(authProvider.notifier).getDioInstance();
      final response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        if (mounted) {
          setState(() {
            _imageBytes = Uint8List.fromList(response.data);
            _cachedUrl = url;
            _isLoading = false;
            _hasError = false;
          });
        }
      } else {
        throw Exception('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _imageBytes = null;
          _cachedUrl = null;
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final processedUrl = UserImageUtils.getUserImageUrl(widget.imageUrl);
    if (processedUrl != null && processedUrl != _cachedUrl) {
      _loadImage(processedUrl);
    } else if (processedUrl == null) {
      setState(() {
        _imageBytes = null;
        _cachedUrl = null;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final processedUrl = UserImageUtils.getUserImageUrl(widget.imageUrl);
    
    // If no URL, show fallback
    if (processedUrl == null) {
      if (widget.isCircle) {
        return UserImageUtils.buildUserAvatar(
          imageUrl: null,
          username: widget.username,
          userId: widget.userId,
          radius: widget.radius ?? 20,
          backgroundColor: widget.backgroundColor,
        );
      }
      return widget.errorWidget ?? 
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.grey[300],
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
        );
    }

    // If loading, show placeholder
    if (_isLoading) {
      return widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor?.withValues(alpha: 0.3) ?? Colors.grey[200],
            borderRadius: widget.isCircle 
              ? null 
              : (widget.borderRadius ?? BorderRadius.circular(8)),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
    }

    // If error, show error widget or fallback
    if (_hasError || _imageBytes == null) {
      if (widget.isCircle) {
        return UserImageUtils.buildUserAvatar(
          imageUrl: null,
          username: widget.username,
          userId: widget.userId,
          radius: widget.radius ?? 20,
          backgroundColor: widget.backgroundColor,
        );
      }
      return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.grey[300],
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
        );
    }

    // Show loaded image
    final image = MemoryImage(_imageBytes!);
    
    if (widget.isCircle) {
      return CircleAvatar(
        radius: widget.radius ?? 20,
        backgroundColor: widget.backgroundColor,
        backgroundImage: image,
        child: widget.username != null && widget.username!.isNotEmpty
          ? null
          : const Icon(Icons.person),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      child: Image(
        image: image,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      ),
    );
  }
}

