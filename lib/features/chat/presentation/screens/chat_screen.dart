import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      'Halo! Saya asisten keuangan Anda. Tanyakan apa saja tentang transaksi dan keuangan Anda.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text, isMe: true));
      _messages.add(const _ChatMessage('Fitur chat bot sedang dikembangkan.'));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _messages.length,
          itemBuilder: (context, index) => _buildBubble(_messages[index]),
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(hintText: 'Ketik pesan...'),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Kirim pesan',
                onPressed: _send,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildBubble(_ChatMessage message) {
    final scheme = Theme.of(context).colorScheme;
    final background = message.isMe
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final foreground = message.isMe
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.text, style: TextStyle(color: foreground)),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage(this.text, {this.isMe = false});

  final String text;
  final bool isMe;
}
