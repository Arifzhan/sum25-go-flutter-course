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
      id: json['id'],
      username: json['username'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };
}

class CreateMessageRequest {
  final String username;
  final String content;

  CreateMessageRequest({
    required this.username,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'content': content,
      };

  String? validate() {
    if (username.isEmpty) return 'Username is required';
    if (content.isEmpty) return 'Content is required';
    return null;
  }
}
