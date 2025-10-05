import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_date/domain/entities/feed_filters.dart';
import 'package:pet_date/domain/entities/user_profile.dart';
import 'package:pet_date/presentation/viewmodels/home_viewmodel.dart';

import 'package:pet_date/domain/repositories/interaction_repository.dart';

class TestInteractionRepository implements InteractionRepository {
  TestInteractionRepository(this.firestore);

  final FakeFirebaseFirestore firestore;

  final _likes = <String>{};
  final _dislikes = <String>{};
  final _superLikes = <String>{};
  final _likesController = StreamController<Set<String>>.broadcast();
  final _dislikesController = StreamController<Set<String>>.broadcast();
  final _superLikesController = StreamController<Set<String>>.broadcast();
  final _matchesController =
      StreamController<Map<String, DateTime?>>.broadcast();

  bool likedBack = false;

  @override
  Future<void> createMatchFor(String a, String b) async {}

  @override
  Future<void> dislikeUser(String currentUserId, String dislikedUserId) async {
    _dislikes.add(dislikedUserId);
    _dislikesController.add(Set.from(_dislikes));
  }

  @override
  Stream<Set<String>> dislikesStream(String uid) => _dislikesController.stream;

  @override
  Future<bool> hasLikedBack(String a, String b) async => likedBack;

  @override
  Future<void> likeUser(String currentUserId, String likedUserId) async {
    _likes.add(likedUserId);
    _likesController.add(Set.from(_likes));
  }

  @override
  Stream<Set<String>> likesStream(String uid) => _likesController.stream;

  @override
  Future<void> superLikeUser(
      String currentUserId, String superLikedUserId) async {
    _superLikes.add(superLikedUserId);
    _superLikesController.add(Set.from(_superLikes));
  }

  @override
  Stream<Set<String>> superLikesStream(String uid) =>
      _superLikesController.stream;

  @override
  Stream<Map<String, DateTime?>> matchesStream(String uid) =>
      _matchesController.stream;

  @override
  Stream<List<UserProfile>> usersStream() {
    return firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final dynamic rawList = data['photoUrls'];
        final List<String> photos;
        if (rawList is List) {
          photos = rawList.whereType<String>().toList();
        } else {
          final fallback = (data['photoUrl'] ?? '').toString();
          photos = fallback.isNotEmpty ? [fallback] : <String>[];
        }
        return UserProfile(
          id: doc.id,
          name: (data['name'] ?? 'User').toString(),
          age: (data['age'] ?? 'Not specified').toString(),
          bio: (data['bio'] ?? 'No description').toString(),
          petName: (data['petName'] ?? 'Pet').toString(),
          petType: (data['petType'] ?? 'Animal').toString(),
          photoUrls: photos,
        );
      }).toList();
    });
  }

  void emitMatches(Map<String, DateTime?> matches) {
    _matchesController.add(matches);
  }

  Future<void> dispose() async {
    await _likesController.close();
    await _dislikesController.close();
    await _superLikesController.close();
    await _matchesController.close();
  }
}

void main() {
  const currentUserId = 'current-user';
  late FakeFirebaseFirestore firestore;
  late TestInteractionRepository interactions;
  late HomeViewModel viewModel;

  Future<void> pumpQueue() => pumpEventQueue(times: 3);

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    interactions = TestInteractionRepository(firestore);

    await firestore.collection('users').doc(currentUserId).set({
      'matchesLastSeen': Timestamp.fromDate(DateTime(2024, 07, 01)),
    });

    await firestore.collection('users').doc('user-a').set({
      'name': 'Alex',
      'age': '28',
      'bio': 'Friendly pup parent',
      'petName': 'Nova',
      'petType': 'Dog',
      'photoUrls': ['url-a'],
    });
    await firestore.collection('users').doc('user-b').set({
      'name': 'Bella',
      'age': '31',
      'bio': 'Cat lover',
      'petName': 'Milo',
      'petType': 'Cat',
      'photoUrls': ['url-b'],
    });

    viewModel = HomeViewModel(
      currentUserId: currentUserId,
      interactions: interactions,
      firestore: firestore,
    );

    await pumpQueue();
  });

  tearDown(() async {
    viewModel.dispose();
    await interactions.dispose();
  });

  test('users list excludes already rated profiles', () async {
    expect(viewModel.users.map((u) => u.id), ['user-a', 'user-b']);

    await interactions.likeUser(currentUserId, 'user-a');
    await pumpQueue();

    expect(viewModel.users.map((u) => u.id), ['user-b']);
  });

  test('match badge toggles when a new match arrives', () async {
    expect(viewModel.hasNewMatches, isFalse);

    interactions.emitMatches({
      'user-a': DateTime(2024, 06, 01),
    });
    await pumpQueue();
    expect(viewModel.hasNewMatches, isFalse);

    interactions.emitMatches({
      'user-b': DateTime(2024, 12, 01),
    });
    await pumpQueue();
    expect(viewModel.hasNewMatches, isTrue);

    await viewModel.markMatchesSeen();
    await pumpQueue();

    expect(viewModel.hasNewMatches, isFalse);
    final doc = await firestore.collection('users').doc(currentUserId).get();
    expect(doc.data()?['matchesLastSeen'], isNotNull);
  });

  test('updateFilters constrains visible users by age and pet type', () async {
    expect(viewModel.availablePetTypes, contains('Dog'));
    expect(viewModel.availablePetTypes, contains('Cat'));

    viewModel.updateFilters(
      FeedFilters(minAge: 29, maxAge: 35, petTypes: {'cat'}),
    );
    await pumpQueue();

    expect(viewModel.users.map((u) => u.id).toList(), ['user-b']);

    viewModel.updateFilters(FeedFilters.defaults());
    await pumpQueue();

    expect(viewModel.users.map((u) => u.id).toList(), ['user-a', 'user-b']);
  });
}
