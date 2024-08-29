import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_date/data/models/user_model.dart';
import 'package:pet_date/data/repositories/user_repository.dart';
import 'package:pet_date/domain/entities/user_pet.dart';

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore firestore;

  FirebaseUserRepository(this.firestore);

  @override
  Future<UserPet> getUser(String id) async {
    final doc = await firestore.collection('users').doc(id).get();
    return UserModel.fromJson(doc.data()!);
  }

  @override
  Future<void> addUser(UserPet user) async {
    await firestore
        .collection('users')
        .doc(user.id)
        .set((user as UserModel).toJson());
  }
}
