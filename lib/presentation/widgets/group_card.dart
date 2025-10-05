import 'package:flutter/material.dart';
import 'package:pet_date/domain/entities/group_info.dart';
import 'package:pet_date/domain/entities/group_request_status.dart';

class GroupCard extends StatelessWidget {
  final GroupInfo group;
  final GroupRequestStatus status;
  final VoidCallback onAction;

  const GroupCard({
    super.key,
    required this.group,
    required this.status,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = status == GroupRequestStatus.pending;
    final isApproved = status == GroupRequestStatus.approved;

    final actionLabel = isApproved
        ? 'Joined'
        : isPending
            ? 'Cancel request'
            : 'Request join';
    final actionColor = isApproved
        ? Colors.green[400]
        : isPending
            ? Colors.orangeAccent
            : Colors.pinkAccent;
    final actionIcon = isApproved
        ? Icons.check_circle
        : isPending
            ? Icons.cancel
            : Icons.group_add;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people,
                          size: 16, color: Colors.pinkAccent),
                      const SizedBox(width: 4),
                      Text(
                        group.membersCount.toString(),
                        style: const TextStyle(
                          color: Colors.pinkAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              group.description,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: isApproved ? null : onAction,
                icon: Icon(actionIcon, size: 18),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.green[300],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
