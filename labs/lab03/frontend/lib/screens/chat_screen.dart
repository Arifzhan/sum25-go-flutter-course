import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'dart:math';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _messageController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).loadMessages();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final username = _usernameController.text.trim();
    final content = _messageController.text.trim();

    if (username.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username and message are required')),
      );
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.createMessage(
      CreateMessageRequest(username: username, content: content),
    );

    if (chatProvider.error == null) {
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully')),
      );
    }
  }

  Future<void> _editMessage(Message message) async {
    final contentController = TextEditingController(text: message.content);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: contentController,
          decoration: const InputDecoration(hintText: 'Enter new message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, contentController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await Provider.of<ChatProvider>(context, listen: false).updateMessage(
        message.id,
        UpdateMessageRequest(content: result),
      );
    }
  }

  Future<void> _deleteMessage(Message message) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Message'),
            content:
                const Text('Are you sure you want to delete this message?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await Provider.of<ChatProvider>(context, listen: false)
          .deleteMessage(message.id);
    }
  }

  Future<void> _showHTTPStatus(int statusCode) async {
    try {
      final status = await Provider.of<ApiService>(context, listen: false)
          .getHTTPStatus(statusCode);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('HTTP Status: ${status.statusCode}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(status.description),
              const SizedBox(height: 16),
              Image.network(status.imageUrl),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Widget _buildMessageTile(Message message) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(message.username[0].toUpperCase()),
      ),
      title: Row(
        children: [
          Text(message.username),
          const Spacer(),
          Text(
            '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      subtitle: Text(message.content),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Text('Edit'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete'),
          ),
        ],
        onSelected: (value) {
          if (value == 'edit') {
            _editMessage(message);
          } else if (value == 'delete') {
            _deleteMessage(message);
          }
        },
      ),
      onTap: () {
        final randomStatus = [200, 404, 500][DateTime.now().second % 3];
        _showHTTPStatus(randomStatus);
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Enter your username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Enter your message',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: _sendMessage,
                child: const Text('Send'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showHTTPStatus(200),
                child: const Text('200 OK'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showHTTPStatus(404),
                child: const Text('404 Not Found'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showHTTPStatus(500),
                child: const Text('500 Error'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            error ?? 'An error occurred',
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Provider.of<ChatProvider>(context, listen: false)
                .loadMessages(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('REST API Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: chatProvider.loadMessages,
          ),
        ],
      ),
      body: chatProvider.isLoading
          ? _buildLoadingWidget()
          : chatProvider.error != null
              ? _buildErrorWidget(chatProvider.error)
              : chatProvider.messages.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('No messages yet'),
                          Text('Send your first message to get started!'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      itemCount: chatProvider.messages.length,
                      itemBuilder: (context, index) {
                        final message = chatProvider
                            .messages[chatProvider.messages.length - 1 - index];
                        return _buildMessageTile(message);
                      },
                    ),
      bottomSheet: _buildMessageInput(),
      floatingActionButton: FloatingActionButton(
        onPressed: chatProvider.loadMessages,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
