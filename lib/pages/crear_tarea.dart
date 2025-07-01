// lib/screens/create_task_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDeadline;
  String? _selectedUserId;
  String? _selectedUserName;

  final _firestore = FirebaseFirestore.instance;

  Future<void> _submitTask() async {
    if (_formKey.currentState!.validate() && _selectedUserId != null) {
      await _firestore.collection('tasks').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'deadline': _selectedDeadline?.toIso8601String(),
        'status': 'iniciando',
        'assignedTo': _selectedUserId,
        'assignedToName': _selectedUserName,
        'createdAt': FieldValue.serverTimestamp()
      });

      Navigator.pop(context);
    }
  }

  Future<void> _pickDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear nueva tarea')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_selectedDeadline == null
                    ? 'Seleccionar fecha límite'
                    : 'Fecha límite: ${_selectedDeadline!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDeadline,
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('rol', isEqualTo: 'colaborador')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final users = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: _selectedUserId,
  decoration: const InputDecoration(labelText: 'Asignar a'),
  items: users.map((doc) {
    final userData = doc.data() as Map<String, dynamic>;
    return DropdownMenuItem(
      value: doc.id,
      child: Text(userData['name'] ?? 'Sin nombre'),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      _selectedUserId = value;

      // Aquí buscamos el nombre del usuario seleccionado
      final selectedDoc = users.firstWhere((doc) => doc.id == value);
      final selectedData = selectedDoc.data() as Map<String, dynamic>;
      _selectedUserName = selectedData['name'];
    });
  },
  validator: (value) => value == null ? 'Selecciona un colaborador' : null,
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitTask,
                child: const Text('Crear Tarea'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
