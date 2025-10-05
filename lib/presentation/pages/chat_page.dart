import 'package:flutter/material.dart';
import 'package:pet_date/presentation/viewmodels/auth_viewmodel.dart';
import 'package:pet_date/presentation/viewmodels/chat_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:pet_date/domain/entities/message_item.dart';
import 'package:pet_date/presentation/widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final TextEditingController _controller;
  String? otherUserId;
  String otherName = 'Chat';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      otherUserId = args['otherUserId'] as String?;
      otherName = (args['otherName'] as String?) ?? otherName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final me = auth.user?.id;
    if (me == null || otherUserId == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.pinkAccent,
          title: Text(otherName, style: const TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: Text('Missing chat context')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(me: me, other: otherUserId!),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.pinkAccent,
          title: Text(otherName, style: const TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<ChatViewModel>(
                builder: (context, vm, _) => StreamBuilder<List<MessageItem>>(
                  stream: vm.messagesStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                        ),
                      );
                    }
                    final messages = snapshot.data!;
                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == me;
                        return MessageBubble(message: msg, isMine: isMe);
                      },
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<ChatViewModel>(
                    builder: (context, vm, _) => IconButton(
                      icon: const Icon(Icons.send, color: Colors.pinkAccent),
                      onPressed: () async {
                        final text = _controller.text.trim();
                        if (text.isEmpty) return;
                        await vm.sendMessage(text);
                        _controller.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
