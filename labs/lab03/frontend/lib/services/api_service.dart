import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import 'dart:async';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  static const Duration timeout = Duration(seconds: 30);
  late http.Client _client;

  ApiService({http.Client? client}) {
    _client = client ?? http.Client();
  }

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
          .get(Uri.parse('$baseUrl/api/messages'), headers: _getHeaders())
          .timeout(timeout);

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw ApiException('Failed to load messages: ${decoded['error']}');
      }

      final apiResponse = ApiResponse<List<Message>>.fromJsonT(decoded);
      if (!apiResponse.success) {
        throw ApiException(apiResponse.error ?? 'Unknown error');
      }

      return apiResponse.data!.map((json) => Message.fromJson(json)).toList();
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      throw ApiException('Failed to load messages: $e');
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
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeout);

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 201) {
        throw ApiException('Failed to create message: ${decoded['error']}');
      }

      final apiResponse = ApiResponse<Message>.fromJsonT(decoded);
      if (!apiResponse.success) {
        throw ApiException(apiResponse.error ?? 'Unknown error');
      }

      return apiResponse.data!;
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      throw ApiException('Failed to create message: $e');
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
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeout);

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw ApiException('Failed to update message: ${decoded['error']}');
      }

      final apiResponse = ApiResponse<Message>.fromJsonT(decoded);
      if (!apiResponse.success) {
        throw ApiException(apiResponse.error ?? 'Unknown error');
      }

      return apiResponse.data!;
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      throw ApiException('Failed to update message: $e');
    }
  }

  Future<void> deleteMessage(int id) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/api/messages/$id'),
            headers: _getHeaders(),
          )
          .timeout(timeout);

      if (response.statusCode != 204) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException('Failed to delete message: ${decoded['error']}');
      }
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      throw ApiException('Failed to delete message: $e');
    }
  }

  Future<HTTPStatusResponse> getHTTPStatus(int statusCode) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/status/$statusCode'),
              headers: _getHeaders())
          .timeout(timeout);

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw ApiException('Failed to get HTTP status: ${decoded['error']}');
      }

      final apiResponse = ApiResponse<HTTPStatusResponse>.fromJsonT(decoded);
      if (!apiResponse.success) {
        throw ApiException(apiResponse.error ?? 'Unknown error');
      }

      return apiResponse.data!;
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      throw ApiException('Failed to get HTTP status: $e');
    }
  }

  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/health'), headers: _getHeaders())
          .timeout(timeout);

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw ApiException('Health check failed: ${decoded['error']}');
      }

      return decoded;
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      throw ApiException('Health check failed: $e');
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
