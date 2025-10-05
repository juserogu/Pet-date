import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pet_date/domain/entities/match_entry.dart';
import 'package:pet_date/domain/entities/user_profile.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

class MatchesViewModel with ChangeNotifier {
  final String uid;
  final FirebaseFirestore firestore;

  MatchesViewModel({required this.uid, FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<MatchEntry>> matchEntriesStream() {
    final matchesStream = firestore
        .collection('users')
        .doc(uid)
        .collection('matches')
        .orderBy('timestamp', descending: true)
        .snapshots();
    final lastSeenStream =
        firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      final ts = data['matchesLastSeen'];
      if (ts is Timestamp) {
        return ts.toDate();
      } else if (ts is DateTime) {
        return ts;
      }
      return null;
    });

    return CombineLatestStream.combine2<QuerySnapshot<Map<String, dynamic>>,
        DateTime?, Tuple2<QuerySnapshot<Map<String, dynamic>>, DateTime?>>(
      matchesStream,
      lastSeenStream,
      (matches, lastSeen) => Tuple2(matches, lastSeen),
    ).asyncMap((tuple) async {
      final matches = tuple.item1;
      final lastSeen = tuple.item2;
      if (matches.docs.isEmpty) {
        return <MatchEntry>[];
      }
      final futures = matches.docs.map((doc) async {
        final matchData = doc.data();
        DateTime? matchedAt;
        final rawTimestamp = matchData['timestamp'];
        if (rawTimestamp is Timestamp) {
          matchedAt = rawTimestamp.toDate();
        } else if (rawTimestamp is DateTime) {
          matchedAt = rawTimestamp;
        }
        final profileDoc =
            await firestore.collection('users').doc(doc.id).get();
        final data = profileDoc.data();
        if (data == null) {
          return null;
        }
        final profile = _mapProfile(profileDoc.id, data);
        final isNew = matchedAt != null &&
            (lastSeen == null || matchedAt.isAfter(lastSeen));
        return MatchEntry(
          profile: profile,
          matchedAt: matchedAt,
          isNew: isNew,
        );
      });

      final entries = await Future.wait(futures);
      return entries.whereType<MatchEntry>().toList();
    });
  }

  UserProfile _mapProfile(String id, Map<String, dynamic> data) {
    final dynamic rawList = data['photoUrls'];
    final List<String> photos;
    if (rawList is List) {
      photos = rawList.whereType<String>().toList();
    } else {
      final fallback = (data['photoUrl'] ?? '').toString();
      photos = fallback.isNotEmpty ? [fallback] : <String>[];
    }
    return UserProfile(
      id: id,
      name: (data['name'] ?? 'User').toString(),
      age: (data['age'] ?? 'Not specified').toString(),
      bio: (data['bio'] ?? 'No description').toString(),
      petName: (data['petName'] ?? 'Pet').toString(),
      petType: (data['petType'] ?? 'Animal').toString(),
      photoUrls: photos,
    );
  }

  Future<void> removeMatch(String otherId) async {
    final batch = firestore.batch();
    final aRef = firestore
        .collection('users')
        .doc(uid)
        .collection('matches')
        .doc(otherId);
    final bRef = firestore
        .collection('users')
        .doc(otherId)
        .collection('matches')
        .doc(uid);
    batch.delete(aRef);
    batch.delete(bRef);
    await batch.commit();
    notifyListeners();
  }

  Future<void> markMatchesSeen() async {
    await firestore.collection('users').doc(uid).set(
      {'matchesLastSeen': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}
