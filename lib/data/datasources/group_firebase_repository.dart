import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_date/data/mappers/group_mapper.dart';
import 'package:pet_date/domain/entities/group_info.dart';
import 'package:pet_date/domain/entities/group_request_status.dart';
import 'package:pet_date/domain/repositories/group_repository.dart';

class FirebaseGroupRepository implements GroupRepository {
  FirebaseGroupRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;

  @override
  Stream<List<GroupInfo>> groupsStream() {
    return firestore.collection('groups').snapshots().map((snapshot) {
      return snapshot.docs.map(GroupMapper.fromDoc).toList();
    });
  }

  @override
  Stream<Map<String, GroupRequestStatus>> requestStatusesStream(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('groupRequests')
        .snapshots()
        .map((snapshot) {
      final map = <String, GroupRequestStatus>{};
      for (final doc in snapshot.docs) {
        map[doc.id] = statusFromString(doc.data()['status'] as String?);
      }
      return map;
    });
  }

  @override
  Future<void> requestJoin(String userId, String groupId) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('groupRequests')
        .doc(groupId)
        .set({
      'status': statusToString(GroupRequestStatus.pending),
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> cancelRequest(String userId, String groupId) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('groupRequests')
        .doc(groupId)
        .delete();
  }
}
