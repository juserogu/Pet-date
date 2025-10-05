import 'package:pet_date/domain/entities/user_profile.dart';

class UserProfileMapper {
  static UserProfile fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final List<String> photos;
    final dynamic rawList = data['photoUrls'];
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
}
