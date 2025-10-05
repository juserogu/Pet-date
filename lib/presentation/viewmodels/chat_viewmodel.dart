import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pet_date/domain/entities/message_item.dart';

class ChatViewModel with ChangeNotifier {
  final String me;
  final String other;
  final FirebaseFirestore firestore;

  late final String chatId;

  ChatViewModel(
      {required this.me, required this.other, FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance {
    final list = [me, other]..sort();
    chatId = '${list.first}_${list.last}';
  }

  Stream<List<MessageItem>> messagesStream() {
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map((doc) => _mapMessage(doc)).toList());
  }

  MessageItem _mapMessage(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final ts = data['timestamp'];
    DateTime time;
    if (ts is Timestamp) {
      time = ts.toDate();
    } else if (ts is DateTime) {
      time = ts;
    } else {
      time = DateTime.now();
    }
    return MessageItem(
      id: doc.id,
      senderId: (data['senderId'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      timestamp: time,
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final chatRef = firestore.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();
    final now = FieldValue.serverTimestamp();
    final batch = firestore.batch();
    batch.set(
        chatRef,
        {
          'participants': [me, other],
          'updatedAt': now,
        },
        SetOptions(merge: true));
    batch.set(msgRef, {
      'senderId': me,
      'text': text,
      'timestamp': now,
    });
    await batch.commit();
  }
}
