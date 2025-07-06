import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MessageApp());
}

class MessageApp extends StatelessWidget {
  const MessageApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => ApiClient(),
      dispose: (context, client) => client.dispose(),
      child: MaterialApp(
        title: 'Community Board',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const MessageBoard(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
