import '../entities/group_info.dart';
import '../entities/group_request_status.dart';

abstract class GroupRepository {
  Stream<List<GroupInfo>> groupsStream();
  Stream<Map<String, GroupRequestStatus>> requestStatusesStream(String userId);

  Future<void> requestJoin(String userId, String groupId);
  Future<void> cancelRequest(String userId, String groupId);
}
