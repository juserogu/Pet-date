import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_date/presentation/viewmodels/profile_viewmodel.dart';

void main() {
  const uid = 'user-123';
  late FakeFirebaseFirestore firestore;
  late MockFirebaseStorage storage;
  late ProfileViewModel viewModel;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    storage = MockFirebaseStorage();
    await firestore.collection('users').doc(uid).set({
      'name': 'Luna',
      'photoUrl': 'https://storage/pets/luna_first.jpg',
      'photoUrls': [
        'https://storage/pets/luna_first.jpg',
        'https://storage/pets/luna_second.jpg',
      ],
    });
    viewModel = ProfileViewModel(
      uid: uid,
      firestore: firestore,
      storage: storage,
    );
  });

  Future<File> createTempImage() async {
    final file = File(
        '${Directory.systemTemp.path}/profile_test_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(List.filled(10, 42));
    return file;
  }

  test('load hydrates user data and photo list', () async {
    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.data['name'], 'Luna');
    expect(viewModel.photoUrls, hasLength(2));
    expect(viewModel.photoUrl, 'https://storage/pets/luna_first.jpg');
  });

  test('uploadPhoto adds new url and persists to firestore', () async {
    await viewModel.load();
    final file = await createTempImage();

    final url = await viewModel.uploadPhoto(file);

    expect(url, isNotNull);
    expect(viewModel.photoUrls.length, 3);
    expect(viewModel.photoUrls.last, url);

    final doc = await firestore.collection('users').doc(uid).get();
    expect(doc.data()?['photoUrls'], viewModel.photoUrls);
  });

  test('removePhoto deletes url and updates primary photo', () async {
    await viewModel.load();
    final initialSecond = viewModel.photoUrls[1];

    await viewModel.removePhoto(initialSecond);

    expect(viewModel.photoUrls, hasLength(1));
    expect(viewModel.photoUrl, viewModel.photoUrls.first);

    final doc = await firestore.collection('users').doc(uid).get();
    expect(doc.data()?['photoUrls'], viewModel.photoUrls);
  });

  test('setPrimaryPhoto moves selected url to first position', () async {
    await viewModel.load();
    final target = viewModel.photoUrls[1];

    await viewModel.setPrimaryPhoto(target);

    expect(viewModel.photoUrls.first, target);
    expect(viewModel.photoUrl, target);

    final doc = await firestore.collection('users').doc(uid).get();
    expect((doc.data()?['photoUrls'] as List).first, target);
  });

  test('reorderPhotos rearranges list and persists order', () async {
    await viewModel.load();

    await viewModel.reorderPhotos(0, 2);

    expect(viewModel.photoUrls.first, 'https://storage/pets/luna_second.jpg');

    final doc = await firestore.collection('users').doc(uid).get();
    expect((doc.data()?['photoUrls'] as List).first,
        'https://storage/pets/luna_second.jpg');
  });
}
