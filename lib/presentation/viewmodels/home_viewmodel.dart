import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pet_date/domain/entities/feed_filters.dart';
import 'package:pet_date/domain/entities/user_profile.dart';
import 'package:pet_date/domain/repositories/interaction_repository.dart';

class HomeViewModel with ChangeNotifier {
  final String currentUserId;
  final InteractionRepository interactions;

  StreamSubscription? _likesSub;
  StreamSubscription? _dislikesSub;
  StreamSubscription? _superLikesSub;
  StreamSubscription? _matchesSub;
  StreamSubscription? _usersSub;
  StreamSubscription? _userDocSub;

  final FirebaseFirestore firestore;

  Set<String> _rated = {};
  List<UserProfile> _allUsers = [];
  List<UserProfile> _users = [];
  Set<String> _availablePetTypes = {};
  FeedFilters _filters = FeedFilters.defaults();

  bool _loading = true;
  bool _hasNewMatches = false;
  DateTime? _lastSeenMatches;
  DateTime? _latestMatchTimestamp;

  List<UserProfile> get users => _users;
  bool get isLoading => _loading;
  bool get hasNewMatches => _hasNewMatches;
  FeedFilters get filters => _filters;
  List<String> get availablePetTypes =>
      _availablePetTypes.map((e) => e).toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  HomeViewModel({
    required this.currentUserId,
    required this.interactions,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance {
    _init();
  }

  void _init() {
    _likesSub = interactions.likesStream(currentUserId).listen((set) {
      _rated = {..._rated, ...set};
      _rebuildVisibleUsers();
    });
    _dislikesSub = interactions.dislikesStream(currentUserId).listen((set) {
      _rated = {..._rated, ...set};
      _rebuildVisibleUsers();
    });
    _superLikesSub = interactions.superLikesStream(currentUserId).listen((set) {
      _rated = {..._rated, ...set};
      _rebuildVisibleUsers();
    });
    _matchesSub = interactions.matchesStream(currentUserId).listen((map) {
      _rated = {..._rated, ...map.keys};
      _latestMatchTimestamp =
          map.values.whereType<DateTime>().fold<DateTime?>(null, (prev, curr) {
        if (prev == null) return curr;
        return curr.isAfter(prev) ? curr : prev;
      });
      _updateMatchBadge();
      _rebuildVisibleUsers();
    });
    _rated.add(currentUserId);

    _userDocSub = firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data == null) return;
      final ts = data['matchesLastSeen'];
      if (ts is Timestamp) {
        _lastSeenMatches = ts.toDate();
        _updateMatchBadge();
      }
    });

    _loadLastSeenMatches();

    _usersSub = interactions.usersStream().listen((profiles) {
      _availablePetTypes = {
        for (final profile in profiles)
          if (profile.petType.trim().isNotEmpty) profile.petType.trim()
      };
      _allUsers =
          profiles.where((profile) => !_rated.contains(profile.id)).toList();
      _loading = false;
      _rebuildVisibleUsers(notify: true);
    });
  }

  Future<void> _loadLastSeenMatches() async {
    final doc = await firestore.collection('users').doc(currentUserId).get();
    final data = doc.data();
    if (data != null) {
      final ts = data['matchesLastSeen'];
      if (ts is Timestamp) {
        _lastSeenMatches = ts.toDate();
      }
    }
    _updateMatchBadge();
  }

  void _updateMatchBadge() {
    final latest = _latestMatchTimestamp;
    final lastSeen = _lastSeenMatches;
    final newValue =
        latest != null && (lastSeen == null || latest.isAfter(lastSeen));
    if (newValue != _hasNewMatches) {
      _hasNewMatches = newValue;
      notifyListeners();
    }
  }

  void _rebuildVisibleUsers({bool notify = true}) {
    final filtered = _allUsers
        .where((user) => !_rated.contains(user.id))
        .where(_matchesFilters)
        .toList();
    _users = filtered;
    if (notify) {
      notifyListeners();
    }
  }

  bool _matchesFilters(UserProfile profile) {
    return _filters.allowsAge(profile.age) &&
        _filters.allowsPetType(profile.petType);
  }

  void updateFilters(FeedFilters filters) {
    if (_filters.isEquivalentTo(filters)) return;
    _filters = filters;
    _rebuildVisibleUsers();
  }

  Future<void> markMatchesSeen() async {
    _lastSeenMatches = DateTime.now();
    _hasNewMatches = false;
    notifyListeners();
    await firestore.collection('users').doc(currentUserId).set({
      'matchesLastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> likeUser(String otherId) async {
    await interactions.likeUser(currentUserId, otherId);
    final matched = await interactions.hasLikedBack(currentUserId, otherId);
    if (matched) await interactions.createMatchFor(currentUserId, otherId);
    return matched;
  }

  Future<void> dislikeUser(String otherId) async {
    await interactions.dislikeUser(currentUserId, otherId);
  }

  Future<bool> superLikeUser(String otherId) async {
    await interactions.superLikeUser(currentUserId, otherId);
    final matched = await interactions.hasLikedBack(currentUserId, otherId);
    if (matched) await interactions.createMatchFor(currentUserId, otherId);
    return matched;
  }

  @override
  void dispose() {
    _likesSub?.cancel();
    _dislikesSub?.cancel();
    _superLikesSub?.cancel();
    _matchesSub?.cancel();
    _usersSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }
}
