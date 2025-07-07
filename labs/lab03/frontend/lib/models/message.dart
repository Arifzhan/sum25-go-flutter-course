class Message {
  final int id;
  final String username;
  final String content;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.username,
    required this.content,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      username: json['username'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          content == other.content &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^ username.hashCode ^ content.hashCode ^ timestamp.hashCode;

  @override
  String toString() {
    return 'Message{id: $id, username: $username, content: $content, timestamp: $timestamp}';
  }
}

class CreateMessageRequest {
  final String username;
  final String content;

  CreateMessageRequest({
    required this.username,
    required this.content,
  });

  factory CreateMessageRequest.fromJson(Map<String, dynamic> json) {
    return CreateMessageRequest(
      username: json['username'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'content': content,
    };
  }

  String? validate() {
    if (username.isEmpty) {
      return "Username is required";
    }
    if (content.isEmpty) {
      return "Content is required";
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateMessageRequest &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          content == other.content;

  @override
  int get hashCode => username.hashCode ^ content.hashCode;

  @override
  String toString() {
    return 'CreateMessageRequest{username: $username, content: $content}';
  }
}

class UpdateMessageRequest {
  final String content;

  UpdateMessageRequest({
    required this.content,
  });

  factory UpdateMessageRequest.fromJson(Map<String, dynamic> json) {
    return UpdateMessageRequest(
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }

  String? validate() {
    if (content.isEmpty) {
      return "Content is required";
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateMessageRequest &&
          runtimeType == other.runtimeType &&
          content == other.content;

  @override
  int get hashCode => content.hashCode;

  @override
  String toString() {
    return 'UpdateMessageRequest{content: $content}';
  }
}

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

  Map<String, dynamic> toJson() {
    return {
      'status_code': statusCode,
      'image_url': imageUrl,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HTTPStatusResponse &&
          runtimeType == other.runtimeType &&
          statusCode == other.statusCode &&
          imageUrl == other.imageUrl &&
          description == other.description;

  @override
  int get hashCode =>
      statusCode.hashCode ^ imageUrl.hashCode ^ description.hashCode;

  @override
  String toString() {
    return 'HTTPStatusResponse{statusCode: $statusCode, imageUrl: $imageUrl, description: $description}';
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'] as Map<String, dynamic>)
          : json['data'] as T?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'error': error,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiResponse &&
          runtimeType == other.runtimeType &&
          success == other.success &&
          data == other.data &&
          error == other.error;

  @override
  int get hashCode => success.hashCode ^ data.hashCode ^ error.hashCode;

  @override
  String toString() {
    return 'ApiResponse{success: $success, data: $data, error: $error}';
  }
}
