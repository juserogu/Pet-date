import '../entities/user_profile.dart';

abstract class InteractionRepository {
  Future<void> likeUser(String currentUserId, String likedUserId);
  Future<void> dislikeUser(String currentUserId, String dislikedUserId);
  Future<void> superLikeUser(String currentUserId, String superLikedUserId);

  Future<bool> hasLikedBack(String a, String b);
  Future<void> createMatchFor(String a, String b);

  Stream<Set<String>> likesStream(String uid);
  Stream<Set<String>> dislikesStream(String uid);
  Stream<Set<String>> superLikesStream(String uid);
  Stream<Map<String, DateTime?>> matchesStream(String uid);

  Stream<List<UserProfile>> usersStream();
}
