import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class MessageBoard extends StatefulWidget {
  const MessageBoard({Key? key}) : super(key: key);

  @override
  State<MessageBoard> createState() => _MessageBoardState();
}

class _MessageBoardState extends State<MessageBoard> {
  late final ApiClient _api;
  final List<ChatPost> _posts = [];
  bool _isFetching = false;
  String? _lastError;
  final TextEditingController _authorInput = TextEditingController();
  final TextEditingController _messageInput = TextEditingController();

  @override
  void initState() {
    super.initState();
    _api = Provider.of<ApiClient>(context, listen: false);
    _refreshPosts();
  }

  @override
  void dispose() {
    _api.dispose();
    _authorInput.dispose();
    _messageInput.dispose();
    super.dispose();
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _isFetching = true;
      _lastError = null;
    });

    try {
      final messages = await _api.fetchPosts();
      setState(() => _posts
        ..clear()
        ..addAll(messages));
    } catch (e) {
      setState(() => _lastError = e.toString());
      _showMessage(e.toString());
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _submitPost() async {
    final request = CreatePostRequest(
      author: _authorInput.text.trim(),
      message: _messageInput.text.trim(),
    );

    final validationError = request.validate();
    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    try {
      final newPost = await _api.createPost(request);
      setState(() => _posts.add(newPost));
      _messageInput.clear();
      _showMessage('Posted successfully');
    } catch (e) {
      _showMessage('Failed to post: ${e.toString()}');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget _buildPostItem(ChatPost post) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(post.author[0])),
        title: Text(post.author),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.content),
            const SizedBox(height: 4),
            Text(
              post.createdAt.toLocal().toString().split('.')[0],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handlePostAction(action, post),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  void _handlePostAction(String action, ChatPost post) {
    switch (action) {
      case 'edit':
        _editPost(post);
        break;
      case 'delete':
        _confirmDelete(post);
        break;
    }
  }

  Future<void> _editPost(ChatPost post) async {
    final controller = TextEditingController(text: post.content);

    final updatedContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(controller: controller),
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

    if (updatedContent != null && updatedContent != post.content) {
      try {
        final request = UpdatePostRequest(newContent: updatedContent);
        final updatedPost = await _api.updatePost(post.postId, request);

        setState(() {
          final index = _posts.indexWhere((p) => p.postId == post.postId);
          if (index != -1) _posts[index] = updatedPost;
        });
      } catch (e) {
        _showMessage('Update failed: ${e.toString()}');
      }
    }
  }

  Future<void> _confirmDelete(ChatPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Delete this message permanently?'),
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
    );

    if (confirmed == true) {
      try {
        await _api.removePost(post.postId);
        setState(() => _posts.removeWhere((p) => p.postId == post.postId));
      } catch (e) {
        _showMessage('Deletion failed: ${e.toString()}');
      }
    }
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _authorInput,
            decoration: const InputDecoration(labelText: 'Your Name'),
          ),
          TextField(
            controller: _messageInput,
            decoration: const InputDecoration(labelText: 'Your Message'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitPost,
            child: const Text('Post Message'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPosts,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isFetching
                ? const Center(child: CircularProgressIndicator())
                : _lastError != null
                    ? Center(child: Text(_lastError!))
                    : _posts.isEmpty
                        ? const Center(child: Text('No messages yet'))
                        : ListView.builder(
                            itemCount: _posts.length,
                            itemBuilder: (context, index) =>
                                _buildPostItem(_posts[index]),
                          ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }
}
