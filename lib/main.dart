import 'package:flutter/material.dart';
import 'services/llama_service.dart';

void main() {
  runApp(const EdithApp());
}

class EdithApp extends StatelessWidget {
  const EdithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edith',
      theme: ThemeData.dark(useMaterial3: true),
      home: const ChatScreen(),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, this.isUser);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final LlamaService _llama = LlamaService();
  final TextEditingController _inputController = TextEditingController();
  final List<ChatMessage> _messages = [];

  bool _isInitializing = true;
  bool _isGenerating = false;
  String _statusMessage = 'Loading model (first run may take a moment)...';

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    try {
      // The native side handles locating/copying the bundled model —
      // no path needs to be passed from Dart anymore.
      final ok = await _llama.initEngine();
      setState(() {
        _isInitializing = false;
        _statusMessage = ok ? '' : 'Failed to load model.';
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    setState(() {
      _messages.add(ChatMessage(text, true));
      _isGenerating = true;
      _inputController.clear();
    });

    try {
      final response = await _llama.infer(text);
      setState(() {
        _messages.add(ChatMessage(response, false));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage('Error: $e', false));
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edith')),
      body: _isInitializing
          ? Center(child: Text(_statusMessage))
          : Column(
              children: [
                if (_statusMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_statusMessage, style: const TextStyle(color: Colors.redAccent)),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: msg.isUser ? Colors.blueGrey.shade700 : Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(msg.text),
                        ),
                      );
                    },
                  ),
                ),
                if (_isGenerating) const LinearProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          decoration: const InputDecoration(hintText: 'Message Edith...'),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _isGenerating ? null : _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
