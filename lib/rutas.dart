import 'package:flutter/material.dart';
import 'package:proyecto_inovacion/pages/registrar.dart';
import 'package:proyecto_inovacion/pages/login.dart';
import 'package:proyecto_inovacion/pages/crear_tarea.dart';
import 'package:proyecto_inovacion/pages/eliminar_usuarios.dart';


final Map<String, Widget Function(BuildContext)> appRoutes = {
 '/register': (context) => const RegisterScreen(),
  '/login': (context) => const LoginScreen(),
  '/asignar_tarea': (context) => const CreateTaskScreen(),
  '/eliminar_usuarios': (context) => const EliminarUsuarioScreen(),
  
};
