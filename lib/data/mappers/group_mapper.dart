import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_date/domain/entities/group_info.dart';

class GroupMapper {
  static GroupInfo fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return GroupInfo(
      id: doc.id,
      name: (data['name'] ?? 'Group').toString(),
      description: (data['description'] ?? '').toString(),
      membersCount: (data['membersCount'] is int)
          ? data['membersCount'] as int
          : int.tryParse((data['membersCount'] ?? '0').toString()) ?? 0,
    );
  }
}
