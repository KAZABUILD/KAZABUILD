library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/models/api_constants.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/guide_model.dart';
import 'package:frontend/models/image_provider.dart';

class GuideService {
  GuideService(this._dio) : _imageService = ImageService(_dio);

  final Dio _dio;
  final ImageService _imageService;

  Future<List<Guide>> fetchGuides({
    String? query,
    List<String>? categories,
    bool paging = false,
    int? page,
    int? pageLength,
    String sortDirection = 'desc',
  }) async {
    final request = <String, dynamic>{
      'Query': query ?? '',
      'Paging': paging && page != null && pageLength != null,
      'SortDirection': sortDirection,
      'OrderBy': 'PostedAt',
    };

    if (request['Paging'] == true) {
      request['Page'] = page;
      request['PageLength'] = pageLength;
    } else {
      request['Paging'] = false;
    }

    if (categories != null && categories.isNotEmpty) {
      request['Category'] = categories;
    }

    if (kDebugMode) {
      print('GuideService.fetchGuides: $request');
    }

    final response = await _dio.post(
      '$apiBaseUrl/UserGuide/get',
      data: request,
    );

    if (response.statusCode != 200 || response.data is! List) {
      throw Exception(
        'Failed to load guides: ${response.statusCode} ${response.statusMessage}',
      );
    }

    final guides = (response.data as List)
        .whereType<Map>()
        .map((item) => Guide.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return _attachImages(guides);
  }

  Future<Guide> fetchGuideById(String id) async {
    final response = await _dio.get('$apiBaseUrl/UserGuide/$id');

    if (response.statusCode != 200 || response.data is! Map) {
      throw Exception('Failed to load guide $id');
    }

    var guide = Guide.fromJson(Map<String, dynamic>.from(response.data as Map));
    final imageId = await _imageService.getGuideImageId(id);
    if (imageId != null && imageId.isNotEmpty) {
      guide = guide.copyWith(imageUrl: ImageService.getImageUrl(imageId));
    }
    return guide;
  }

  Future<Guide> createGuide({
    required String title,
    required String author,
    required String category,
    required double timeToReadMinutes,
    required DateTime postedAt,
    required String text,
  }) async {
    // Ensure validation requirements are met
    if (title.trim().length < 5 || title.trim().length > 100) {
      throw Exception('Title must be between 5 and 100 characters');
    }
    if (author.trim().length < 5 || author.trim().length > 50) {
      throw Exception('Author must be between 5 and 50 characters');
    }
    if (category.trim().length < 5 || category.trim().length > 50) {
      throw Exception('Category must be between 5 and 50 characters');
    }
    if (text.trim().length < 50) {
      throw Exception('Text must be at least 50 characters');
    }
    if (timeToReadMinutes < 0 || timeToReadMinutes > 1000) {
      throw Exception('TimeToRead must be between 0 and 1000 minutes');
    }

    final payload = {
      'Title': title.trim(),
      'Author': author.trim(),
      'Category': category.trim(),
      'TimeToRead': timeToReadMinutes.toDouble(), // Ensure it's a number
      'PostedAt': postedAt.toUtc().toIso8601String(),
      'Text': text.trim(),
    };

    try {
      final response = await _dio.post(
        '$apiBaseUrl/UserGuide/add',
        data: payload,
      );
      final id = response.data['id'] ?? response.data['Id'];
      if (id == null) {
        throw Exception('Guide created but ID missing in response');
      }

      return fetchGuideById(id.toString());
    } on DioException catch (e) {
      // Handle validation errors from backend
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        String errorMessage = 'Validation failed';

        if (errorData is Map) {
          // Try to extract validation errors
          if (errorData.containsKey('errors')) {
            final errors = errorData['errors'] as Map?;
            if (errors != null && errors.isNotEmpty) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMessage = firstError.first.toString();
              } else if (firstError is String) {
                errorMessage = firstError;
              }
            }
          } else if (errorData.containsKey('title')) {
            errorMessage = errorData['title'].toString();
          } else if (errorData.containsKey('detail')) {
            errorMessage = errorData['detail'].toString();
          }
        }
        throw Exception(errorMessage);
      }
      rethrow;
    }
  }

  Future<Guide> updateGuide(
    String id, {
    String? title,
    String? author,
    String? category,
    double? timeToReadMinutes,
    DateTime? postedAt,
    String? text,
    String? note,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) payload['Title'] = title.trim();
    if (author != null) payload['Author'] = author.trim();
    if (category != null) payload['Category'] = category.trim();
    if (timeToReadMinutes != null) payload['TimeToRead'] = timeToReadMinutes;
    if (postedAt != null)
      payload['PostedAt'] = postedAt.toUtc().toIso8601String();
    if (text != null) payload['Text'] = text.trim();
    if (note != null)
      payload['Note'] = note.trim().isEmpty ? null : note.trim();

    if (payload.isEmpty) {
      return fetchGuideById(id);
    }

    await _dio.put('$apiBaseUrl/UserGuide/$id', data: payload);
    return fetchGuideById(id);
  }

  Future<void> deleteGuide(String id) async {
    await _dio.delete('$apiBaseUrl/UserGuide/$id');
  }

  Future<List<Guide>> _attachImages(List<Guide> guides) async {
    if (guides.isEmpty) return guides;

    final ids = guides.map((g) => g.id).where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return guides;

    final imageMap = await _imageService.getGuideImageIds(ids);

    return guides.map((guide) {
      final imageId = imageMap[guide.id];
      if (imageId == null || imageId.isEmpty) return guide;
      return guide.copyWith(imageUrl: ImageService.getImageUrl(imageId));
    }).toList();
  }
}

final guideServiceProvider = Provider<GuideService>((ref) {
  final dio = ref.watch(authProvider.notifier).getDioInstance();
  return GuideService(dio);
});

final guidesProvider = FutureProvider.autoDispose<List<Guide>>((ref) async {
  final service = ref.watch(guideServiceProvider);
  return service.fetchGuides();
});
