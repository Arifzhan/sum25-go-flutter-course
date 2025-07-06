import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiClient {
  static const String apiBaseUrl = 'http://localhost:8080';
  static const Duration defaultTimeout = Duration(seconds: 30);
  final http.Client _http;

  ApiClient({http.Client? client}) : _http = client ?? http.Client();

  void dispose() => _http.close();

  Future<List<ChatPost>> fetchPosts() async {
    try {
      final response = await _http
          .get(Uri.parse('$apiBaseUrl/api/messages'))
          .timeout(defaultTimeout);

      return _parsePostList(response);
    } catch (e) {
      _handleNetworkIssue(e);
    }
  }

  List<ChatPost> _parsePostList(http.Response response) {
    final json = jsonDecode(response.body);

    if (json is List) {
      return json.map((e) => ChatPost.fromJson(e)).toList();
    } else if (json is Map && json['data'] is List) {
      return (json['data'] as List).map((e) => ChatPost.fromJson(e)).toList();
    }
    throw ApiException('Unexpected response format');
  }

  Future<ChatPost> createPost(CreatePostRequest request) async {
    try {
      final response = await _http
          .post(
            Uri.parse('$apiBaseUrl/api/messages'),
            body: jsonEncode(request.toJson()),
            headers: _defaultHeaders(),
          )
          .timeout(defaultTimeout);

      return _handlePostResponse(response);
    } catch (e) {
      _handleNetworkIssue(e);
    }
  }

  Future<ChatPost> updatePost(int postId, UpdatePostRequest request) async {
    try {
      final response = await _http
          .put(
            Uri.parse('$apiBaseUrl/api/messages/$postId'),
            body: jsonEncode(request.toJson()),
            headers: _defaultHeaders(),
          )
          .timeout(defaultTimeout);

      return _handlePostResponse(response);
    } catch (e) {
      _handleNetworkIssue(e);
    }
  }

  ChatPost _handlePostResponse(http.Response response) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['success'] != true) {
      throw ApiException(json['error'] ?? 'Operation failed');
    }

    if (json['data'] == null) {
      throw ApiException('No data received');
    }

    try {
      return ChatPost.fromJson(json['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiException('Invalid post format: $e');
    }
  }

  Future<void> removePost(int postId) async {
    try {
      final response = await _http
          .delete(Uri.parse('$apiBaseUrl/api/messages/$postId'))
          .timeout(defaultTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(jsonDecode(response.body)?['error'] ??
            'Failed with status ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkIssue(e);
    }
  }

  Map<String, String> _defaultHeaders() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Never _handleNetworkIssue(Object e) {
    if (e is SocketException) {
      throw NetworkException('Network unavailable');
    } else if (e is TimeoutException) {
      throw NetworkException('Request timed out');
    }
    throw ApiException('Request failed: ${e.toString()}');
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'API Error: $message';
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message);
}
