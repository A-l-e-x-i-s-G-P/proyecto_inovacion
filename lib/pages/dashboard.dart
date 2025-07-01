// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_inovacion/models/usuarios.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  AppUser? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          currentUser = AppUser.fromMap(doc.data()!);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ...existing code...
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${currentUser!.rol.toUpperCase()}'),
        actions: [
          if (currentUser!.rol == 'jefe')
            IconButton(
              icon: const Icon(Icons.add_task),
              tooltip: 'Asignar tarea',
              onPressed: () {
                Navigator.pushNamed(context, '/asignar_tarea');
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body:
          currentUser!.rol == 'jefe'
              ? const TasksForBoss()
              : const TasksForCollaborator(),
    );
    // ...existing code...
  }
}

Future<String?> uploadToCloudinary(File imageFile) async {
  const cloudName = 'darb7zamp';
  const uploadPreset = 'flutter'; // asegúrate que existe en tu cuenta

  final mimeType = lookupMimeType(imageFile.path);
  final url = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/auto/upload',
  );

  final request =
      http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
            contentType:
                mimeType != null
                    ? MediaType.parse(mimeType)
                    : MediaType('application', 'octet-stream'),
          ),
        );

  final response = await request.send();

  if (response.statusCode == 200) {
    final respData = await http.Response.fromStream(response);
    final urlMatch = RegExp(
      r'"secure_url"\s*:\s*"([^"]+)"',
    ).firstMatch(respData.body);
    print('✅ Imagen subida exitosamente: ${urlMatch?.group(1)}');
    return urlMatch?.group(1);
  } else {
    print('❌ Error al subir imagen: ${response.statusCode}');
    final errorBody = await response.stream.bytesToString();
    print(
      '🪵 Respuesta del servidor: $errorBody',
    ); // Esto te dará la pista exacta del error
    return null;
  }
}

class TasksForBoss extends StatefulWidget {
  const TasksForBoss({super.key});

  @override
  State<TasksForBoss> createState() => _TasksForBossState();
}

class _TasksForBossState extends State<TasksForBoss> {
  String filterEstado = 'todos';

  @override
  Widget build(BuildContext context) {
    final _firestore = FirebaseFirestore.instance;
    Query query = _firestore.collection('tasks');
    if (filterEstado != 'todos') {
      query = query.where('status', isEqualTo: filterEstado);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<String>(
            value: filterEstado,
            onChanged: (value) {
              setState(() {
                filterEstado = value!;
              });
            },
            items:
                ['todos', 'iniciando', 'en_proceso', 'ejecutando', 'finalizado']
                    .map(
                      (estado) =>
                          DropdownMenuItem(value: estado, child: Text(estado)),
                    )
                    .toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();

              final tasks = snapshot.data!.docs;

              if (tasks.isEmpty) {
                return const Center(child: Text('No hay tareas aún.'));
              }

              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index].data()! as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: const Icon(Icons.edit),
      onPressed: () {
        if (task['status'] != 'finalizado') {
          _mostrarDialogoEditar(context, task, tasks[index].id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se puede editar una tarea finalizada.'),
            ),
          );
        }
      },
    ),
    IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () async {
        if ((task['status'] ?? '') != 'finalizado') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La tarea aún no está finalizada.')),
          );
          return;
        }

        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar tarea'),
            content: const Text('¿Estás seguro de que deseas eliminar esta tarea?'),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Eliminar'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await FirebaseFirestore.instance
              .collection('tasks')
              .doc(tasks[index].id)
              .delete();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarea eliminada correctamente.')),
          );
        }
      },
    ),
    
  ],
),

                      title: Text(task['title'] ?? 'Sin título'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estado: ${task['status']}'),
                          if (task.containsKey('description'))
                            Text('Descripción: ${task['description']}'),
                          if (task.containsKey('deadline'))
                            Text('Fecha límite: ${task['deadline']}'),
                          if (task.containsKey('assignedToName'))
  Text('Asignado a: ${task['assignedToName']}'),

if (task.containsKey('evidencias'))
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      const Text('Evidencias:', style: TextStyle(fontWeight: FontWeight.bold)),
      ...List<Widget>.from((task['evidencias'] as List).map((evidencia) {
        return ElevatedButton.icon(
          icon: const Icon(Icons.insert_drive_file),
          label: const Text('Abrir evidencia'),
          onPressed: () {
            final url = evidencia['url'];
            if (url != null) {
              descargarYabrirArchivo(context, url);
            }
          },
        );
      })),
    ],
  ),
                          if (task['evidencias'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                const Text('Evidencias:'),
                                ...List<Widget>.from(
                                  (task['evidencias'] as List).map((ev) {
                                    final url = ev['url'] ?? '';
                                    final isImage =
                                        url.endsWith('.jpg') ||
                                        url.endsWith('.png') ||
                                        url.endsWith('.jpeg') ||
                                        url.contains('image');
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child:
                                          isImage
                                              ? Image.network(url, height: 150)
                                              : TextButton(
                                                onPressed: () async {
                                                  await abrirURL(context, url);
                                                },
                                                child: Text(
                                                  'Ver archivo: $url',
                                                ),
                                              ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _mostrarDialogoEditar(BuildContext context, Map<String, dynamic> task, String taskId) {
  final titleController = TextEditingController(text: task['title']);
  final descriptionController = TextEditingController(text: task['description']);
  final deadlineController = TextEditingController(text: task['deadline']);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Editar Tarea'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(labelText: 'Fecha límite'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('tasks')
                .doc(taskId)
                .update({
              'title': titleController.text,
              'description': descriptionController.text,
              'deadline': deadlineController.text,
            });
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}


 Future<void> abrirURL(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.inAppWebView); // ← cambia aquí
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo abrir el archivo: $url')),
    );
  }
}

Future<void> descargarYabrirArchivo(BuildContext context, String url) async {
  try {
    final dio = Dio();
    final nombreArchivo = url.split('/').last;

    final dir = await getTemporaryDirectory();
    final archivo = File('${dir.path}/$nombreArchivo');

    final respuesta = await dio.download(url, archivo.path);

    if (respuesta.statusCode == 200) {
      await OpenFile.open(archivo.path);
    } else {
      throw Exception('No se pudo descargar el archivo');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al abrir archivo: $e')),
    );
    print('Error al abrir archivo: $e');
  }
}




}

class TasksForCollaborator extends StatelessWidget {
  const TasksForCollaborator({super.key});

  Future<void> subirEvidencia(BuildContext context, String taskId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = File(result.files.single.path!);
      final url = await uploadToCloudinary(file);

      if (url != null) {
        await FirebaseFirestore.instance.collection('tasks').doc(taskId).update(
          {
            'evidencias': FieldValue.arrayUnion([
              {'tipo': 'archivo', 'url': url},
            ]),
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al subir la evidencia a Cloudinary'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _auth = FirebaseAuth.instance;
    final _firestore = FirebaseFirestore.instance;
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Usuario no autenticado'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('tasks')
              .where('assignedTo', isEqualTo: currentUser.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final tasks = snapshot.data!.docs;

        if (tasks.isEmpty) {
          return const Center(child: Text('No tienes tareas asignadas.'));
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index].data()! as Map<String, dynamic>;
            final taskId = tasks[index].id;
            String estado = task['status'];

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(task['title']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estado: $estado'),
                    DropdownButton<String>(
                      value: estado,
                      onChanged: (nuevo) {
                        FirebaseFirestore.instance
                            .collection('tasks')
                            .doc(taskId)
                            .update({'status': nuevo});
                      },
                      items:
                          [
                                'iniciando',
                                'en_proceso',
                                'ejecutando',
                                'finalizado',
                              ]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                    ),
                    if (estado == 'finalizado')
                      ElevatedButton(
                        onPressed: () => subirEvidencia(context, taskId),
                        child: const Text('Subir evidencia'),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
