import 'package:flutter/material.dart';
import 'package:proyecto_inovacion/pages/registrar.dart';
import 'package:proyecto_inovacion/pages/login.dart';
import 'package:proyecto_inovacion/pages/dashboard.dart';
import 'package:proyecto_inovacion/pages/crear_tarea.dart';


final Map<String, Widget Function(BuildContext)> appRoutes = {
 '/register': (context) => const RegisterScreen(),
  '/login': (context) => const LoginScreen(),
  '/dashboard': (context) => const DashboardScreen(),
  '/asignar_tarea': (context) => const CreateTaskScreen(),
};
