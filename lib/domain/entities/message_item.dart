class MessageItem {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  const MessageItem({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });
}
