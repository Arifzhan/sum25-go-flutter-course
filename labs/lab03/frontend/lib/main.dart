import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'services/api_service.dart';
import 'models/message.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
          dispose: (_, apiService) => apiService.dispose(),
        ),
        ChangeNotifierProxyProvider<ApiService, ChatProvider>(
          create: (context) => ChatProvider(
            context.read<ApiService>(),
          ),
          update: (context, apiService, chatProvider) =>
              chatProvider ?? ChatProvider(apiService),
        ),
      ],
      child: MaterialApp(
        title: 'REST API Chat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            secondary: Colors.orange,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 1,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          useMaterial3: true,
        ),
        home: const ChatScreen(),
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        ),
      ),
    );
  }
}

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  bool _isFirstLoad = true;
  DateTime? _lastUpdated;

  ChatProvider(this._apiService);

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFirstLoad => _isFirstLoad;
  DateTime? get lastUpdated => _lastUpdated;

  Future<void> loadMessages({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newMessages = await _apiService.getMessages();
      _messages = newMessages;
      _isFirstLoad = false;
      _lastUpdated = DateTime.now();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      if (_isFirstLoad) {
        _messages = [];
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      if (_isFirstLoad) {
        _messages = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createMessage(CreateMessageRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final message = await _apiService.createMessage(request);
      _messages.insert(0, message);
      _error = null;
      _lastUpdated = DateTime.now();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to send message';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMessage(int id, UpdateMessageRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final updatedMessage = await _apiService.updateMessage(id, request);
      final index = _messages.indexWhere((m) => m.id == id);
      if (index != -1) {
        _messages[index] = updatedMessage;
        _lastUpdated = DateTime.now();
      }
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to update message';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMessage(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.deleteMessage(id);
      _messages.removeWhere((m) => m.id == id);
      _lastUpdated = DateTime.now();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to delete message';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMessages() async {
    await loadMessages(forceRefresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool shouldRefresh() {
    return _lastUpdated == null ||
        DateTime.now().difference(_lastUpdated!) > const Duration(minutes: 5);
  }
}
