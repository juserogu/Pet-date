import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_date/domain/entities/match_entry.dart';
import 'package:pet_date/presentation/viewmodels/matches_viewmodel.dart';

void main() {
  const uid = 'me';
  late FakeFirebaseFirestore firestore;
  late MatchesViewModel viewModel;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc(uid).set({
      'matchesLastSeen': Timestamp.fromDate(DateTime(2024, 7, 1)),
    });
    await firestore.collection('users').doc('match-old').set({
      'name': 'Alex',
      'age': '28',
      'bio': 'Friendly pup parent',
      'petName': 'Nova',
      'petType': 'Dog',
      'photoUrls': ['url-a'],
    });
    await firestore.collection('users').doc('match-new').set({
      'name': 'Bella',
      'age': '31',
      'bio': 'Cat lover',
      'petName': 'Milo',
      'petType': 'Cat',
      'photoUrls': ['url-b'],
    });
    viewModel = MatchesViewModel(uid: uid, firestore: firestore);
  });

  tearDown(() async {
    viewModel.dispose();
  });

  test('entries flag matches newer than last seen', () async {
    await firestore
        .collection('users')
        .doc(uid)
        .collection('matches')
        .doc('match-old')
        .set({
      'timestamp': Timestamp.fromDate(DateTime(2024, 6, 1)),
    });

    await firestore
        .collection('users')
        .doc(uid)
        .collection('matches')
        .doc('match-new')
        .set({
      'timestamp': Timestamp.fromDate(DateTime(2024, 12, 1)),
    });

    final queue = StreamQueue(viewModel.matchEntriesStream());

    Future<List<MatchEntry>> waitFor(
        bool Function(List<MatchEntry>) predicate) async {
      while (true) {
        final next = await queue.next;
        if (predicate(next)) return next;
      }
    }

    final firstEmission = await waitFor((entries) => entries.length == 2);

    final oldEntry =
        firstEmission.firstWhere((e) => e.profile.id == 'match-old');
    final newEntry =
        firstEmission.firstWhere((e) => e.profile.id == 'match-new');

    expect(oldEntry.isNew, isFalse);
    expect(newEntry.isNew, isTrue);

    await viewModel.markMatchesSeen();

    final afterSeen = await waitFor((entries) => entries.isNotEmpty);
    final refreshedNewEntry =
        afterSeen.firstWhere((e) => e.profile.id == 'match-new');

    expect(refreshedNewEntry.isNew, isFalse);

    await queue.cancel();
  });
}
