// lib/screens/eliminar_usuario.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EliminarUsuarioScreen extends StatefulWidget {
  const EliminarUsuarioScreen({super.key});

  @override
  State<EliminarUsuarioScreen> createState() => _EliminarUsuarioScreenState();
}

class _EliminarUsuarioScreenState extends State<EliminarUsuarioScreen> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _eliminarUsuario(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar este usuario? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado correctamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eliminar Usuarios')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              final nombre = data['name'] ?? 'Sin nombre';
              final username = data['username'] ?? 'Sin usuario';
              final rol = data['rol'] ?? 'Sin rol';

              return ListTile(
                title: Text(nombre),
                subtitle: Text('Usuario: $username  |  Rol: $rol'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarUsuario(user.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
