import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:proyecto_inovacion/models/usuarios.dart';  // Aquí importas tu modelo AppUser
import 'package:proyecto_inovacion/pages/dashboard.dart'; // Asegúrate de importar tu DashboardScreen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  Future<void> _login() async {
  final username = _usernameController.text.trim();
  final password = _passController.text.trim();

  if (username.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Llena todos los campos')),
    );
    return;
  }

  try {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no encontrado')),
      );
      return;
    }

    final userDoc = query.docs.first;
    final userData = userDoc.data();
    final userId = userDoc.id;

    final storedHash = userData['passwordHash'] ?? '';
    final passwordOk = BCrypt.checkpw(password, storedHash);

    if (!passwordOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña incorrecta')),
      );
      return;
    }

    // Iniciar sesión anónima en Firebase Auth
    await FirebaseAuth.instance.signInAnonymously();

    // Construir el AppUser con el uid real (de Firestore)
    final usuario = AppUser.fromMap({
      ...userData,
      'uid': userId,
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(currentUser: usuario),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
    print('Error al iniciar sesión: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Iniciar sesión")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Nombre de usuario"),
            ),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Contraseña"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _login, child: const Text("Entrar")),
          ],
        ),
      ),
    );
  }
}
