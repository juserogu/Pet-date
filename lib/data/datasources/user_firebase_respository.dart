import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_date/data/mappers/user_profile_mapper.dart';
import 'package:pet_date/domain/entities/user_profile.dart';
import 'package:pet_date/domain/repositories/user_repository.dart';

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore firestore;

  FirebaseUserRepository(this.firestore);

  @override
  Future<UserProfile> getUser(String id) async {
    final doc = await firestore.collection('users').doc(id).get();
    final data = doc.data();
    if (data == null) {
      throw StateError('User not found');
    }
    return UserProfileMapper.fromFirestore(doc.id, data);
  }

  @override
  @override
  Future<void> addUser(UserProfile user) async {
    await firestore.collection('users').doc(user.id).set({
      'id': user.id,
      'uid': user.id,
      'name': user.name,
      'email': '',
      'age': user.age,
      'bio': user.bio,
      'petName': user.petName,
      'petType': user.petType,
      'photoUrls': user.photoUrls,
      'photoUrl': user.primaryPhotoUrl,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await firestore
        .collection('users')
        .doc(id)
        .set(data, SetOptions(merge: true));
  }
}
