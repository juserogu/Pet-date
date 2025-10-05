import 'package:flutter/material.dart';
import 'package:pet_date/domain/entities/match_entry.dart';

class MatchTile extends StatelessWidget {
  final MatchEntry entry;
  final VoidCallback onChat;
  final VoidCallback onRemove;

  const MatchTile({
    super.key,
    required this.entry,
    required this.onChat,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final profile = entry.profile;
    final primaryPhoto = profile.primaryPhotoUrl;
    final ImageProvider? avatarImage =
        primaryPhoto.isNotEmpty ? NetworkImage(primaryPhoto) : null;

    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.pinkAccent,
            backgroundImage: avatarImage,
            child: avatarImage == null
                ? const Icon(Icons.pets, color: Colors.white)
                : null,
          ),
          if (entry.isNew)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(child: Text(profile.name)),
          if (entry.isNew)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
        ],
      ),
      subtitle: Text('Owner of ${profile.petName}'),
      trailing: ElevatedButton(
        onPressed: onChat,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pinkAccent,
        ),
        child: const Text('Chat', style: TextStyle(color: Colors.white)),
      ),
      onLongPress: onRemove,
    );
  }
}
