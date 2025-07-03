import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String taskId;
  final String username; // ✅ Se recibe el username al navegar

  const ChatScreen({super.key, required this.taskId, required this.username});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Mapa {username: nombre completo}
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _loadUserNames();
  }

  Future<void> _loadUserNames() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final Map<String, String> names = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final name = data['name'] ?? 'Sin nombre';
      final username = data['username'];
      if (username != null) {
        names[username] = name;
      }
    }
    setState(() {
      _userNames = names;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat de la tarea')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .doc(widget.taskId)
                  .collection('chat')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final senderUsername = msg['username'] ?? '';
                    final isMine = senderUsername == widget.username;
                    final time = (msg['timestamp'] as Timestamp).toDate();
                    final formattedTime = DateFormat('HH:mm').format(time);

                    final senderName = _userNames[senderUsername] ?? 'Usuario desconocido';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment:
                            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMine ? Colors.blue[200] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(msg['text'] ?? '', style: const TextStyle(fontSize: 16)),
                          ),
                          Text(formattedTime, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Escribe un mensaje...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskId)
        .collection('chat')
        .add({
      'text': text,
      'username': widget.username, // ✅ usamos el username pasado al widget
      'timestamp': Timestamp.now(),
    });

    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }
}
