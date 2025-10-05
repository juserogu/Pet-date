class UserProfile {
  final String id;
  final String name;
  final String age;
  final String bio;
  final String petName;
  final String petType;
  final List<String> photoUrls;

  const UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.petName,
    required this.petType,
    required this.photoUrls,
  });

  String get primaryPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : '';

  UserProfile copyWith({
    String? id,
    String? name,
    String? age,
    String? bio,
    String? petName,
    String? petType,
    List<String>? photoUrls,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      petName: petName ?? this.petName,
      petType: petType ?? this.petType,
      photoUrls: photoUrls ?? List<String>.from(this.photoUrls),
    );
  }
}
