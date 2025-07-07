import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  static const Duration timeout = Duration(seconds: 30);
  late http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  void dispose() {
    _client.close();
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<List<Message>> getMessages() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/messages'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          final data = decoded['data'] as List;
          return data.map((json) => Message.fromJson(json)).toList();
        }
        throw ApiException(decoded['error'] ?? 'Failed to get messages');
      }
      throw ApiException('Server returned ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<Message> createMessage(CreateMessageRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      throw ValidationException(validationError);
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/messages'),
            headers: _getHeaders(),
            body: json.encode(request.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          return Message.fromJson(decoded['data']);
        }
        throw ApiException(decoded['error'] ?? 'Failed to create message');
      }
      throw ApiException('Server returned ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<Message> updateMessage(int id, UpdateMessageRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      throw ValidationException(validationError);
    }

    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/api/messages/$id'),
            headers: _getHeaders(),
            body: json.encode(request.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          return Message.fromJson(decoded['data']);
        }
        throw ApiException(decoded['error'] ?? 'Failed to update message');
      }
      throw ApiException('Server returned ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<void> deleteMessage(int id) async {
    try {
      final response = await _client
          .delete(Uri.parse('$baseUrl/api/messages/$id'))
          .timeout(timeout);

      if (response.statusCode != 204) {
        throw ApiException('Failed to delete message');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<HTTPStatusResponse> getHTTPStatus(int statusCode) async {
    if (statusCode < 100 || statusCode > 599) {
      throw ValidationException('Invalid HTTP status code');
    }

    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/status/$statusCode'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          return HTTPStatusResponse.fromJson(decoded['data']);
        }
        throw ApiException(decoded['error'] ?? 'Failed to get HTTP status');
      }
      throw ApiException('Server returned ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response =
          await _client.get(Uri.parse('$baseUrl/api/health')).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw ApiException('Health check failed');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }
}

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
