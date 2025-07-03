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

  List<String> selectedUserIds = [];
  List<String> selectedUserNames = [];

  String? _taskBossId;
  String? _taskBossName;

  final _firestore = FirebaseFirestore.instance;

  Future<void> _submitTask() async {
    if (_formKey.currentState!.validate() && selectedUserIds.isNotEmpty && _taskBossId != null) {
      await _firestore.collection('tasks').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'deadline': _selectedDeadline?.toIso8601String(),
        'status': 'iniciando',
        'assignedTo': selectedUserIds,
        'assignedToNames': selectedUserNames,
        'taskBossId': _taskBossId,
        'taskBossName': _taskBossName,
        'createdAt': FieldValue.serverTimestamp()
      });

      Navigator.pop(context);
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
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
              const SizedBox(height: 20),

              // 🔹 Selección de colaboradores (CheckboxListTile)
              const Text('Seleccionar colaboradores:', style: TextStyle(fontWeight: FontWeight.bold)),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').where('rol', isEqualTo: 'colaborador').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final users = snapshot.data!.docs;

                  return Column(
                    children: users.map((doc) {
                      final userData = doc.data()! as Map<String, dynamic>;
                      final uid = doc.id;
                      final name = userData['name'] ?? 'Sin nombre';
                      final isSelected = selectedUserIds.contains(uid);

                      return CheckboxListTile(
                        title: Text(name),
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedUserIds.add(uid);
                              selectedUserNames.add(name);
                            } else {
                              selectedUserIds.remove(uid);
                              selectedUserNames.remove(name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 16),

              // 🔹 Selección del jefe de tarea (Dropdown)
              const Text('Seleccionar jefe de tarea:', style: TextStyle(fontWeight: FontWeight.bold)),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').where('rol', whereIn: ['colaborador', 'jefe']).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final users = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Jefe de tarea'),
                    value: _taskBossId,
                    onChanged: (value) {
                      setState(() {
                        _taskBossId = value;
                        final selectedDoc = users.firstWhere((doc) => doc.id == value);
                        final data = selectedDoc.data()! as Map<String, dynamic>;
                        _taskBossName = data['name'];
                      });
                    },
                    items: users.map((doc) {
                      final data = doc.data()! as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['name'] ?? 'Sin nombre'),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Selecciona un jefe de tarea' : null,
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
