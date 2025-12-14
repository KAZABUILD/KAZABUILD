/// This file defines the state management for messaging interactions, including
/// fetching messages, sending new ones, updating, and deleting messages.
///
/// It uses Riverpod to provide services and state notifiers for the messaging feature.
library;

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/models/message_model.dart';

/// A service class to handle API requests related to messages.
class MessageService {
  final Dio _dio;

  MessageService(this._dio);

  /// Sends a new message.
  /// POST /Messages/add
  Future<Response> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? title,
  }) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/Messages/add',
        data: {
          'SenderId': senderId,
          'ReceiverId': receiverId,
          'Content': content,
          'Title': title ?? content.substring(0, content.length > 50 ? 50 : content.length),
          'SentAt': DateTime.now().toIso8601String(),
          'MessageType': 'USER', // Regular user message
          'IsRead': false,
        },
      );
      return response;
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Updates a message.
  /// PUT /Messages/{id}
  /// Users can modify only if the messages they received were read, while staff can modify all.
  Future<Response> updateMessage({
    required String messageId,
    required String content,
  }) async {
    try {
      final response = await _dio.put(
        '$apiBaseUrl/Messages/$messageId',
        data: {
          'Content': content,
        },
      );
      return response;
    } catch (e) {
      debugPrint('Error updating message: $e');
      rethrow;
    }
  }

  /// Gets a message by ID.
  /// GET /Messages/{id}
  /// Different level of information returned based on privileges.
  Future<Message> getMessageById(String messageId) async {
    try {
      final response = await _dio.get('$apiBaseUrl/Messages/$messageId');
      return Message.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching message: $e');
      rethrow;
    }
  }

  /// Deletes a message.
  /// DELETE /Messages/{id}
  /// Users can delete messages they sent and staff can delete all.
  Future<Response> deleteMessage(String messageId) async {
    try {
      final response = await _dio.delete('$apiBaseUrl/Messages/$messageId');
      return response;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  /// Gets messages with pagination and search.
  /// POST /Messages/get
  /// Different level of information returned based on privileges.
  Future<List<Message>> getMessages({
    String? senderId,
    String? receiverId,
    bool? isRead,
    String? query,
    int page = 1,
    int pageSize = 20,
    String? orderBy,
    String sortDirection = 'desc',
  }) async {
    try {
      final Map<String, dynamic> filter = {
        'Paging': true,
        'Page': page,
        'PageLength': pageSize,
        'SortDirection': sortDirection,
      };

      if (senderId != null && senderId.isNotEmpty) {
        filter['SenderId'] = [senderId];
      }

      if (receiverId != null && receiverId.isNotEmpty) {
        filter['ReceiverId'] = [receiverId];
      }

      if (isRead != null) {
        filter['IsRead'] = isRead;
      }

      if (query != null && query.isNotEmpty) {
        filter['Query'] = query;
      }

      if (orderBy != null && orderBy.isNotEmpty) {
        filter['OrderBy'] = orderBy;
      } else {
        filter['OrderBy'] = 'SentAt'; // Use SentAt instead of CreatedAt (Message entity field name)
      }

      debugPrint('Fetching messages with filter: $filter');

      final response = await _dio.post('$apiBaseUrl/Messages/get', data: filter);

      final List<dynamic> messagesJson = response.data as List<dynamic>? ?? [];
      return messagesJson.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      rethrow;
    }
  }
}

/// A provider that creates an instance of [MessageService] with an authenticated Dio client.
final messageServiceProvider = Provider<MessageService>((ref) {
  // Get the authorized Dio instance from the authProvider to make authenticated requests.
  final dio = ref.watch(authProvider.notifier).getDioInstance();
  return MessageService(dio);
});

/// Parameters for paginated messages fetching.
class MessagesParams {
  final String? senderId;
  final String? receiverId;
  final bool? isRead;
  final String? query;
  final int page;
  final int pageSize;
  final String? orderBy;
  final String sortDirection;

  MessagesParams({
    this.senderId,
    this.receiverId,
    this.isRead,
    this.query,
    this.page = 1,
    this.pageSize = 20,
    this.orderBy,
    this.sortDirection = 'desc',
  });

  MessagesParams copyWith({
    String? senderId,
    String? receiverId,
    bool? isRead,
    String? query,
    int? page,
    int? pageSize,
    String? orderBy,
    String? sortDirection,
  }) {
    return MessagesParams(
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      isRead: isRead ?? this.isRead,
      query: query ?? this.query,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      orderBy: orderBy ?? this.orderBy,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessagesParams &&
        other.senderId == senderId &&
        other.receiverId == receiverId &&
        other.isRead == isRead &&
        other.query == query &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.orderBy == orderBy &&
        other.sortDirection == sortDirection;
  }

  @override
  int get hashCode {
    return Object.hash(
      senderId,
      receiverId,
      isRead,
      query,
      page,
      pageSize,
      orderBy,
      sortDirection,
    );
  }
}

/// A provider that fetches paginated messages based on parameters.
final messagesProvider = FutureProvider.family<List<Message>, MessagesParams>((ref, params) async {
  final messageService = ref.watch(messageServiceProvider);
  return messageService.getMessages(
    senderId: params.senderId,
    receiverId: params.receiverId,
    isRead: params.isRead,
    query: params.query,
    page: params.page,
    pageSize: params.pageSize,
    orderBy: params.orderBy,
    sortDirection: params.sortDirection,
  );
});

/// Manages the state for messaging operations.
class MessageNotifier extends StateNotifier<AsyncValue<void>> {
  final MessageService _messageService;
  final Ref _ref;

  MessageNotifier(this._messageService, this._ref) : super(const AsyncValue.data(null));

  /// Sends a new message.
  Future<String> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? title,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _messageService.sendMessage(
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        title: title,
      );
      state = const AsyncValue.data(null);
      // Invalidate messages providers to refetch the list.
      _ref.invalidate(messagesProvider);
      return response.data['message'] ?? 'Message sent successfully!';
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Updates a message.
  Future<String> updateMessage({
    required String messageId,
    required String content,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _messageService.updateMessage(
        messageId: messageId,
        content: content,
      );
      state = const AsyncValue.data(null);
      // Invalidate messages providers to refetch the list.
      _ref.invalidate(messagesProvider);
      return response.data['message'] ?? 'Message updated successfully!';
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Deletes a message.
  Future<String> deleteMessage(String messageId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _messageService.deleteMessage(messageId);
      state = const AsyncValue.data(null);
      // Invalidate messages providers to refetch the list.
      _ref.invalidate(messagesProvider);
      return response.data['message'] ?? 'Message deleted successfully!';
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

/// Provider for the MessageNotifier.
final messageProvider = StateNotifierProvider<MessageNotifier, AsyncValue<void>>((ref) {
  return MessageNotifier(ref.watch(messageServiceProvider), ref);
});

