import 'package:flutter/material.dart';
import 'package:pet_date/domain/entities/message_item.dart';

class MessageBubble extends StatelessWidget {
  final MessageItem message;
  final bool isMine;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMine ? Colors.pinkAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: TextStyle(
              color: isMine ? Colors.white : Colors.black87, fontSize: 15),
        ),
      ),
    );
  }
}
