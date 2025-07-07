import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import 'dart:math';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _usernameController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final username = _usernameController.text.trim();
    final content = _messageController.text.trim();

    if (username.isEmpty || content.isEmpty) {
      _showSnackBar('Please enter both username and message');
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    try {
      await chatProvider.createMessage(
        CreateMessageRequest(username: username, content: content),
      );
      _messageController.clear();
      _scrollToBottom();
      _showSnackBar('Message sent successfully');
    } catch (e) {
      _showSnackBar('Failed to send message: ${e.toString()}');
    }
  }

  Future<void> _deleteMessage(int id) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    try {
      await chatProvider.deleteMessage(id);
      _showSnackBar('Message deleted');
    } catch (e) {
      _showSnackBar('Failed to delete message: ${e.toString()}');
    }
  }

  Future<void> _editMessage(Message message) async {
    final controller = TextEditingController(text: message.content);
    final newContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter your message',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newContent != null && newContent != message.content) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      try {
        await chatProvider.updateMessage(
          message.id,
          UpdateMessageRequest(content: newContent),
        );
        _showSnackBar('Message updated');
      } catch (e) {
        _showSnackBar('Failed to update message: ${e.toString()}');
      }
    }
  }

  void _showHttpStatusDialog() async {
    final statusCodes = [200, 201, 400, 404, 418, 500, 503];
    final randomCode = statusCodes[Random().nextInt(statusCodes.length)];

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getHTTPStatus(randomCode);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('HTTP ${response.statusCode}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(response.description),
              const SizedBox(height: 16),
              Image.network(
                response.imageUrl,
                height: 200,
                errorBuilder: (_, __, ___) => const Icon(Icons.error),
              ),
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
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REST API Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<ChatProvider>(context, listen: false)
                .refreshMessages(),
            tooltip: 'Refresh messages',
          ),
          IconButton(
            icon: const Icon(Icons.pets),
            onPressed: _showHttpStatusDialog,
            tooltip: 'Show HTTP Cat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                if (chatProvider.isLoading && chatProvider.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (chatProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(chatProvider.error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: chatProvider.refreshMessages,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (chatProvider.messages.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return Dismissible(
                      key: Key(message.id.toString()),
                      background: Container(color: Colors.red),
                      onDismissed: (_) => _deleteMessage(message.id),
                      child: ListTile(
                        title: Text(message.username),
                        subtitle: Text(message.content),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                          ],
                          onSelected: (_) => _editMessage(message),
                        ),
                        onTap: _showHttpStatusDialog,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  tooltip: 'Send message',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scrollToBottom(),
        child: const Icon(Icons.arrow_downward),
      ),
    );
  }
}
