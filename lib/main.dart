import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Agrega esto
import 'package:proyecto_inovacion/rutas.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Agrega esta línea
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {                                                                                      
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mejora de comunicaciones',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: appRoutes,
    );

  }
}