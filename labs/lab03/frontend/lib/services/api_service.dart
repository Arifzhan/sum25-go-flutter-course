import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

// Класс для обработки HTTP ответов с информацией о статусе
class HTTPStatusResponse {
  final int statusCode;
  final String imageUrl;
  final String description;

  HTTPStatusResponse({
    required this.statusCode,
    required this.imageUrl,
    required this.description,
  });

  factory HTTPStatusResponse.fromJson(Map<String, dynamic> json) {
    return HTTPStatusResponse(
      statusCode: json['status_code'] as int,
      imageUrl: json['image_url'] as String,
      description: json['description'] as String,
    );
  }
}

// Класс для запроса на обновление сообщения
class UpdateMessageRequest {
  final String content;

  UpdateMessageRequest({required this.content});

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }

  String? validate() {
    if (content.isEmpty) {
      return 'Content cannot be empty';
    }
    return null;
  }
}

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  static const Duration timeout = Duration(seconds: 30);
  final http.Client client;

  ApiService({http.Client? client}) : client = client ?? http.Client();

  void dispose() {
    client.close();
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Основной метод обработки ответов
  T _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          return fromJson(decoded['data'] as Map<String, dynamic>);
        }
        throw ApiException(decoded['error'] ?? 'Request failed');
      } catch (e) {
        throw ApiException('Invalid response format');
      }
    } else {
      try {
        final error = json.decode(response.body)?['error']?.toString();
        throw ApiException(
            error ?? 'Request failed with status ${response.statusCode}');
      } catch (e) {
        throw ApiException('Request failed with status ${response.statusCode}');
      }
    }
  }

  // Методы для работы с сообщениями
  Future<List<Message>> getMessages() async {
    final response = await client
        .get(Uri.parse('$baseUrl/api/messages'), headers: _getHeaders())
        .timeout(timeout);

    try {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded['success'] == true && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw ApiException(decoded['error'] ?? 'Failed to load messages');
    } catch (e) {
      throw ApiException('Failed to load messages: ${e.toString()}');
    }
  }

  Future<Message> createMessage(CreateMessageRequest request) async {
    final error = request.validate();
    if (error != null) throw ValidationException(error);

    final response = await client
        .post(
          Uri.parse('$baseUrl/api/messages'),
          headers: _getHeaders(),
          body: json.encode(request.toJson()),
        )
        .timeout(timeout);

    return _handleResponse<Message>(response, Message.fromJson);
  }

  Future<Message> updateMessage(int id, UpdateMessageRequest request) async {
    final error = request.validate();
    if (error != null) throw ValidationException(error);

    final response = await client
        .put(
          Uri.parse('$baseUrl/api/messages/$id'),
          headers: _getHeaders(),
          body: json.encode({'content': request.content}),
        )
        .timeout(timeout);

    return _handleResponse<Message>(response, Message.fromJson);
  }

  Future<void> deleteMessage(int id) async {
    final response = await client
        .delete(Uri.parse('$baseUrl/api/messages/$id'), headers: _getHeaders())
        .timeout(timeout);

    if (response.statusCode != 204) {
      throw ApiException('Failed to delete message');
    }
  }

  // Метод для получения HTTP статусов
  Future<HTTPStatusResponse> getHTTPStatus(int statusCode) async {
    if (statusCode < 100 || statusCode > 599) {
      throw ValidationException('Status code must be between 100 and 599');
    }

    final response = await client
        .get(Uri.parse('$baseUrl/api/status/$statusCode'),
            headers: _getHeaders())
        .timeout(timeout);

    try {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded['success'] == true) {
        final data = decoded['data'] as Map<String, dynamic>;
        return HTTPStatusResponse.fromJson(data);
      }
      throw ApiException(decoded['error'] ?? 'Failed to get status');
    } catch (e) {
      throw ApiException('Failed to get status: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> healthCheck() async {
    final response = await client
        .get(Uri.parse('$baseUrl/api/health'), headers: _getHeaders())
        .timeout(timeout);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Health check failed');
  }
}

// Классы исключений
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message);
}

class ValidationException extends ApiException {
  ValidationException(String message) : super(message);
}
