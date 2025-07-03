import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Agrega esto
import 'package:proyecto_inovacion/rutas.dart';
import 'package:proyecto_inovacion/pages/chat.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Agrega esta línea
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {                                                                                      
  const MyApp({super.key});
// ...existing code...
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mejora de comunicaciones',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: appRoutes,
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
    final args = settings.arguments as Map<String, dynamic>;
    final taskId = args['taskId'] as String;
    final username = args['username'] as String;

    return MaterialPageRoute(
      builder: (context) => ChatScreen(taskId: taskId, username: username),
    );
  }
      },

    );
  }
// ...existing code...
}