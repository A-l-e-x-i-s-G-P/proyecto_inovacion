import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_inovacion/models/usuarios.dart';
import 'package:bcrypt/bcrypt.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passController = TextEditingController();

  String _selectedRole = 'colaborador';

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final name = _nameController.text.trim();
    final password = _passController.text.trim();

    if (username.isEmpty || name.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos')),
      );
      return;
    }

    try {
      // Verificar si ya existe el username
      final existing = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nombre de usuario ya existe')),
        );
        return;
      }

      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      final newUser = <String, dynamic>{
        'name': name,
        'username': username,
        'passwordHash': hashedPassword,
        'rol': _selectedRole,
      };

      final docRef = await _firestore.collection('users').add(newUser);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario creado con éxito')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear usuario")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nombre completo"),
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Nombre de usuario"),
            ),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Contraseña"),
            ),
            DropdownButton<String>(
              value: _selectedRole,
              items: const [
                DropdownMenuItem(value: 'colaborador', child: Text('Colaborador')),
                DropdownMenuItem(value: 'jefe', child: Text('Jefe')),
              ],
              onChanged: (value) => setState(() => _selectedRole = value!),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _register, child: const Text("Crear usuario")),
          ],
        ),
      ),
    );
  }
}
