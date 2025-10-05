import 'user_profile.dart';

class MatchEntry {
  final UserProfile profile;
  final DateTime? matchedAt;
  final bool isNew;

  const MatchEntry({
    required this.profile,
    required this.matchedAt,
    required this.isNew,
  });
}
