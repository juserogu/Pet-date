import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_date/domain/entities/user_profile.dart';
import 'package:pet_date/domain/repositories/interaction_repository.dart';
import 'package:pet_date/data/mappers/user_profile_mapper.dart';

class FirebaseInteractionRepository implements InteractionRepository {
  final FirebaseFirestore firestore;

  FirebaseInteractionRepository(this.firestore);

  @override
  Future<void> likeUser(String currentUserId, String likedUserId) async {
    await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('likes')
        .doc(likedUserId)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'like',
    });
  }

  @override
  Future<void> dislikeUser(String currentUserId, String dislikedUserId) async {
    await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('dislikes')
        .doc(dislikedUserId)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'dislike',
    });
  }

  @override
  Future<void> superLikeUser(
      String currentUserId, String superLikedUserId) async {
    await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('superLikes')
        .doc(superLikedUserId)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'superLike',
    });
  }

  @override
  Future<bool> hasLikedBack(String a, String b) async {
    final likedBack = await firestore
        .collection('users')
        .doc(b)
        .collection('likes')
        .doc(a)
        .get();
    final superLikedBack = await firestore
        .collection('users')
        .doc(b)
        .collection('superLikes')
        .doc(a)
        .get();
    return likedBack.exists || superLikedBack.exists;
  }

  @override
  Future<void> createMatchFor(String a, String b) async {
    final batch = firestore.batch();
    final now = FieldValue.serverTimestamp();
    final aRef =
        firestore.collection('users').doc(a).collection('matches').doc(b);
    final bRef =
        firestore.collection('users').doc(b).collection('matches').doc(a);
    batch.set(aRef, {'timestamp': now, 'with': b}, SetOptions(merge: true));
    batch.set(bRef, {'timestamp': now, 'with': a}, SetOptions(merge: true));
    await batch.commit();
  }

  @override
  Stream<Set<String>> likesStream(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('likes')
        .snapshots()
        .map((qs) => qs.docs.map((d) => d.id).toSet());
  }

  @override
  Stream<Set<String>> dislikesStream(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('dislikes')
        .snapshots()
        .map((qs) => qs.docs.map((d) => d.id).toSet());
  }

  @override
  Stream<Set<String>> superLikesStream(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('superLikes')
        .snapshots()
        .map((qs) => qs.docs.map((d) => d.id).toSet());
  }

  @override
  Stream<Map<String, DateTime?>> matchesStream(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('matches')
        .snapshots()
        .map((qs) {
      final map = <String, DateTime?>{};
      for (final doc in qs.docs) {
        final data = doc.data();
        final ts = data['timestamp'];
        DateTime? time;
        if (ts is Timestamp) {
          time = ts.toDate();
        } else if (ts is DateTime) {
          time = ts;
        }
        map[doc.id] = time;
      }
      return map;
    });
  }

  @override
  Stream<List<UserProfile>> usersStream() {
    return firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfileMapper.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }
}
