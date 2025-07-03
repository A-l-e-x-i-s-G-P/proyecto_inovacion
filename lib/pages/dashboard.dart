// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
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

class DashboardScreen extends StatelessWidget {
  final AppUser currentUser;

  const DashboardScreen({required this.currentUser, super.key});

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${currentUser.rol.toUpperCase()}'),
        actions: [
          if (currentUser.rol == 'jefe') ...[
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Registrar usuario',
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_remove),
              tooltip: 'Eliminar usuarios',
              onPressed: () {
                Navigator.pushNamed(context, '/eliminar_usuarios');
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_task),
              tooltip: 'Asignar tarea',
              onPressed: () {
                Navigator.pushNamed(context, '/asignar_tarea');
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: (currentUser.rol == 'jefe' || currentUser.rol == 'jefe_tarea')
          ? TasksForBoss(
      currentUserId: currentUser.uid,
      isGeneralBoss: currentUser.rol == 'jefe',
      currentUsername: currentUser.username, // <-- pasa el username
    )
  : TasksForCollaborator(
      currentUserId: currentUser.uid,
      currentUsername: currentUser.username, // <-- pasa el username
    ),
    );
  }
}

class TasksForBoss extends StatelessWidget {
  final String currentUserId;
  final bool isGeneralBoss;
  final String currentUsername; // nuevo

  const TasksForBoss({
    required this.currentUserId,
    required this.isGeneralBoss,
    required this.currentUsername, // nuevo
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    Query query = firestore.collection('tasks');
    if (!isGeneralBoss) {
      query = query.where('jefeTareaId', isEqualTo: currentUserId);
    }

    return StreamBuilder<QuerySnapshot>(
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
    final taskId = tasks[index].id;

    final jefeTareaId = task['jefeTareaId']?.toString().trim();
    final currentUserIdTrim = currentUserId.trim();

    final puedeEditar = isGeneralBoss || (jefeTareaId == currentUserIdTrim);

    return Card(
  margin: const EdgeInsets.all(8),
  child: Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height / 3, // max 1/3 altura pantalla
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botones siempre visibles arriba
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: puedeEditar
                ? [
                  IconButton(
  icon: const Icon(Icons.chat),
  tooltip: 'Ir al chat',
  onPressed: () {
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'taskId': taskId,
        'username': currentUsername,
      },
    );
  },
),

                    IconButton(
                      icon: const Icon(Icons.group),
                      tooltip: 'Editar colaboradores',
                      onPressed: () {
                        final colaboradores = (task['colaboradores'] ?? []) as List<dynamic>;
                        _mostrarDialogoEditarColaboradores(context, taskId, colaboradores);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar tarea',
                      onPressed: () {
                        if (task['status'] != 'finalizado') {
                          _mostrarDialogoEditar(context, task, taskId);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se puede editar una tarea finalizada.')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Eliminar tarea',
                      onPressed: () => _eliminarTarea(context, taskId, task['status']),
                    ),
                  ]
                : [],
          ),
        ),

        // Contenido scrollable dentro de la tarjeta
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task['title'] ?? 'Sin título', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Estado: ${task['status']}'),
                if (task.containsKey('description')) Text('Descripción: ${task['description']}'),
                if (task.containsKey('deadline')) Text('Fecha límite: ${task['deadline']}'),
                if (task.containsKey('assignedToNames'))
                  Text('Asignados: ${(task['assignedToNames'] as List).join(', ')}'),
                if (task.containsKey('taskBossName')) Text('Jefe de tarea: ${task['taskBossName']}'),
                if (task['evidencias'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Text('Evidencias:'),
                      const SizedBox(height: 4),
                      ...List<Widget>.generate(
                        (task['evidencias'] as List).length,
                        (i) {
                          final ev = (task['evidencias'] as List)[i];
                          final url = ev['url'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.visibility),
                              label: Text('Ver evidencia ${i + 1}'),
                              onPressed: () => abrirURL(context, url),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
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
  void _mostrarDialogoEditarColaboradores(BuildContext context, String taskId, List<dynamic> colaboradoresActuales) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('rol', isEqualTo: 'colaborador')
      .get();

  final todosColaboradores = snapshot.docs;
  List<String> seleccionados = List<String>.from(colaboradoresActuales);

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Editar colaboradores'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: todosColaboradores.map((doc) {
              final userId = doc.id;
              final userData = doc.data();
              final nombre = userData['name'] ?? 'Sin nombre';

              final yaSeleccionado = seleccionados.contains(userId);

              return CheckboxListTile(
                value: yaSeleccionado,
                title: Text(nombre),
                onChanged: (valor) {
                  setState(() {
                    if (valor == true) {
                      seleccionados.add(userId);
                    } else {
                      seleccionados.remove(userId);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              List<String> nombres = todosColaboradores
                  .where((doc) => seleccionados.contains(doc.id))
                  .map((doc) => doc['name'] ?? 'Sin nombre')
                  .cast<String>()
                  .toList();

              await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
                'colaboradores': seleccionados,
                'assignedTo': seleccionados,
                'assignedToNames': nombres,
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Colaboradores actualizados')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
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
            await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
              'title': titleController.text,
              'description': descriptionController.text,
              'deadline': deadlineController.text,
            });

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tarea actualizada')),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}


  void _eliminarTarea(BuildContext context, String taskId, String status) async {
  if (status != 'finalizado') {
    if (Navigator.of(context).canPop()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La tarea aún no está finalizada.')),
      );
    }
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
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tarea eliminada correctamente.')),
    );
  }
}

}

Future<String?> uploadToCloudinary(File imageFile) async {
  const cloudName = 'darb7zamp';
  const uploadPreset = 'flutter';

  final mimeType = lookupMimeType(imageFile.path);
  final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');

  final request = http.MultipartRequest('POST', url)
    ..fields['upload_preset'] = uploadPreset
    ..files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: mimeType != null ? MediaType.parse(mimeType) : MediaType('application', 'octet-stream'),
    ));

  final response = await request.send();

  if (response.statusCode == 200) {
    final respData = await http.Response.fromStream(response);
    final urlMatch = RegExp(r'"secure_url"\s*:\s*"([^"]+)"').firstMatch(respData.body);
    return urlMatch?.group(1);
  } else {
    return null;
  }
}

Future<void> abrirURL(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.inAppWebView);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir el archivo: $url')));
  }
}

Future<void> descargarYabrirArchivo(BuildContext context, String url) async {
  try {
    final dio = Dio();
    final nombreArchivo = url.split('/').last.split('?').first;
    final dir = await getTemporaryDirectory();
    final archivo = File('${dir.path}/$nombreArchivo');
    final respuesta = await dio.download(url, archivo.path);

    if (respuesta.statusCode == 200) {
      await OpenFile.open(archivo.path);
    } else {
      throw Exception('No se pudo descargar el archivo');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al abrir archivo: $e')));
  }
}

class TasksForCollaborator extends StatelessWidget {
  final String currentUserId;
  final String currentUsername; // nuevo

  const TasksForCollaborator({
    required this.currentUserId,
    required this.currentUsername, // nuevo
    super.key,
  });
   @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('tasks').where('assignedTo', arrayContains: currentUserId).snapshots(),
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
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height / 3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4, left: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DropdownButton<String>(
                            value: estado,
                            onChanged: (nuevo) {
                              FirebaseFirestore.instance.collection('tasks').doc(taskId).update({'status': nuevo});
                            },
                            items: ['iniciando', 'en_proceso', 'ejecutando', 'finalizado']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                          ),
                           Row(
                            children: [
                              IconButton(
  icon: const Icon(Icons.chat),
  tooltip: 'Ir al chat',
  onPressed: () {
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'taskId': taskId,
        'username': currentUsername,
      },
    );
  },
),

                              if (estado == 'finalizado')
                                ElevatedButton(
                                  onPressed: () => subirEvidencia(context, taskId),
                                  child: const Text('Subir evidencia'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task['title'] ?? 'Sin título', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Estado: ${task['status']}'),
                            if (task.containsKey('description')) Text('Descripción: ${task['description']}'),
                            if (task.containsKey('deadline')) Text('Fecha límite: ${task['deadline']}'),
                            if (task.containsKey('assignedToNames'))
                              Text('Asignados: ${(task['assignedToNames'] as List).join(', ')}'),
                            if (task.containsKey('taskBossName')) Text('Jefe de tarea: ${task['taskBossName']}'),
                            if (task.containsKey('evidencias')) ...[
                              const SizedBox(height: 8),
                              const Text('Evidencias:'),
                             ...List<Widget>.generate(
  (task['evidencias'] as List).length,
  (i) {
    final ev = (task['evidencias'] as List)[i];
    final url = ev['url'] ?? '';
    final subidoPor = ev['subidoPor'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => descargarYabrirArchivo(context, url),
              child: Text('Abrir evidencia ${i + 1}'),
            ),
          ),
          if (subidoPor == currentUserId) // 👈 Solo si es del usuario actual
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
                  'evidencias': FieldValue.arrayRemove([ev]),
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Evidencia eliminada.')),
                );
              },
            ),
        ],
      ),
    );
  },
),

                            ],
                          ],
                        ),
                      ),
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

  Future<void> subirEvidencia(BuildContext context, String taskId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = File(result.files.single.path!);
      final url = await uploadToCloudinary(file);

      if (url != null) {
        await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
  'evidencias': FieldValue.arrayUnion([
    {
      'tipo': 'archivo',
      'url': url,
      'subidoPor': currentUserId, // 👈 Guardamos quién subió la evidencia
    }
  ]),
});

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evidencia subida correctamente.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir la evidencia a Cloudinary')));
      }
    }
  }
  Future<void> eliminarEvidencia(BuildContext context, String taskId, Map<String, dynamic> evidencia) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar evidencia'),
        content: const Text('¿Deseas eliminar esta evidencia?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'evidencias': FieldValue.arrayRemove([evidencia]),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evidencia eliminada correctamente.')));
    }
  }
}

