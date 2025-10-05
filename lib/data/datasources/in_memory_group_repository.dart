import 'dart:async';

import 'package:pet_date/domain/entities/group_info.dart';
import 'package:pet_date/domain/entities/group_request_status.dart';
import 'package:pet_date/domain/repositories/group_repository.dart';

class InMemoryGroupRepository implements GroupRepository {
  InMemoryGroupRepository._internal() {
    _groupsController.add(_groups);
  }

  static final InMemoryGroupRepository instance =
      InMemoryGroupRepository._internal();

  final List<GroupInfo> _groups = const [
    GroupInfo(
      id: 'group-dogs',
      name: 'Dog Lovers Hub',
      description:
          'Share tips, arrange playdates and swap cute stories about your pups.',
      membersCount: 128,
    ),
    GroupInfo(
      id: 'group-cats',
      name: 'Cat Guardians',
      description:
          'Everything about feline friends: care, nutrition and fun facts.',
      membersCount: 94,
    ),
    GroupInfo(
      id: 'group-trainers',
      name: 'Pet Trainers Club',
      description:
          'Connect with trainers and share training routines that work.',
      membersCount: 56,
    ),
  ];

  final _groupsController = StreamController<List<GroupInfo>>.broadcast();
  final Map<String, StreamController<Map<String, GroupRequestStatus>>>
      _statusControllers = {};
  final Map<String, Map<String, GroupRequestStatus>> _statusMap = {};

  StreamController<Map<String, GroupRequestStatus>> _controllerFor(
      String userId) {
    return _statusControllers.putIfAbsent(userId, () {
      final controller =
          StreamController<Map<String, GroupRequestStatus>>.broadcast();
      controller.add(Map<String, GroupRequestStatus>.from(
          _statusMap[userId] ?? <String, GroupRequestStatus>{}));
      return controller;
    });
  }

  Map<String, GroupRequestStatus> _statusFor(String userId) {
    return _statusMap.putIfAbsent(userId, () => <String, GroupRequestStatus>{});
  }

  void _emit(String userId) {
    final controller = _controllerFor(userId);
    if (!controller.isClosed) {
      controller.add(Map<String, GroupRequestStatus>.from(_statusFor(userId)));
    }
  }

  @override
  Stream<List<GroupInfo>> groupsStream() => _groupsController.stream;

  @override
  Stream<Map<String, GroupRequestStatus>> requestStatusesStream(
          String userId) =>
      _controllerFor(userId).stream;

  @override
  Future<void> requestJoin(String userId, String groupId) async {
    final map = _statusFor(userId);
    if (map[groupId] != GroupRequestStatus.pending) {
      map[groupId] = GroupRequestStatus.pending;
      _emit(userId);
    }
  }

  @override
  Future<void> cancelRequest(String userId, String groupId) async {
    final map = _statusFor(userId);
    if (map.remove(groupId) != null) {
      _emit(userId);
    }
  }
}
