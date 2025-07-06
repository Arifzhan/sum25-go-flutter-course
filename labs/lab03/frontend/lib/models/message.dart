class ChatPost {
  final int postId;
  final String author;
  final String content;
  final DateTime createdAt;

  ChatPost({
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  factory ChatPost.fromJson(Map<String, dynamic> json) {
    try {
      final timestamp = json['timestamp'] is String
          ? DateTime.parse(json['timestamp'])
          : DateTime.now();

      return ChatPost(
        postId: int.parse(json['id'].toString()),
        author: json['username'].toString(),
        content: json['content'].toString(),
        createdAt: timestamp,
      );
    } catch (e, stack) {
      print('Error parsing post: $e\n$stack\nData: $json');
      throw FormatException('Post parsing failed: $e');
    }
  }
}

class CreatePostRequest {
  final String author;
  final String message;

  CreatePostRequest({
    required this.author,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'username': author,
        'content': message,
      };

  String? validate() {
    if (author.isEmpty) return "Author name is required";
    if (message.isEmpty) return "Message content is required";
    return null;
  }
}

class UpdatePostRequest {
  final String newContent;

  UpdatePostRequest({
    required this.newContent,
  });

  Map<String, dynamic> toJson() => {
        'content': newContent,
      };

  String? validate() {
    if (newContent.isEmpty) return "Message cannot be empty";
    return null;
  }
}

class HttpStatusInfo {
  final int statusCode;
  final String imageLink;
  final String statusText;

  HttpStatusInfo({
    required this.statusCode,
    required this.imageLink,
    required this.statusText,
  });

  factory HttpStatusInfo.fromJson(Map<String, dynamic> json) {
    return HttpStatusInfo(
      statusCode: int.tryParse(json['status_code'].toString()) ?? 0,
      imageLink: json['image_url']?.toString() ?? '',
      statusText: json['description']?.toString() ?? '',
    );
  }
}

class ApiResult<T> {
  final bool isSuccess;
  final T? resultData;
  final String? errorMessage;

  ApiResult({
    required this.isSuccess,
    this.resultData,
    this.errorMessage,
  });

  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? parseData,
  ) {
    return ApiResult<T>(
      isSuccess: json['success'] as bool,
      resultData: json['data'] != null && parseData != null
          ? parseData(json['data'])
          : null,
      errorMessage: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson(T Function(T)? convertData) {
    return {
      'success': isSuccess,
      'data': resultData != null && convertData != null
          ? convertData(resultData!)
          : resultData,
      'error': errorMessage,
    };
  }
}
