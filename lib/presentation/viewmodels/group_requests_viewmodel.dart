import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pet_date/domain/entities/group_info.dart';
import 'package:pet_date/domain/entities/group_request_status.dart';
import 'package:pet_date/domain/repositories/group_repository.dart';

class GroupRequestsViewModel with ChangeNotifier {
  final String userId;
  final GroupRepository repository;

  GroupRequestsViewModel({required this.userId, required this.repository}) {
    _listen();
  }

  StreamSubscription<List<GroupInfo>>? _groupsSub;
  StreamSubscription<Map<String, GroupRequestStatus>>? _statusSub;

  List<GroupInfo> _groups = [];
  Map<String, GroupRequestStatus> _statuses = {};
  bool _loading = true;

  List<GroupInfo> get groups => _groups;
  bool get isLoading => _loading;

  GroupRequestStatus statusFor(String groupId) =>
      _statuses[groupId] ?? GroupRequestStatus.none;

  void _listen() {
    _groupsSub = repository.groupsStream().listen((data) {
      _groups = data;
      _loading = false;
      notifyListeners();
    });
    _statusSub = repository.requestStatusesStream(userId).listen((statuses) {
      _statuses = statuses;
      notifyListeners();
    });
  }

  Future<void> requestJoin(String groupId) async {
    await repository.requestJoin(userId, groupId);
  }

  Future<void> cancelRequest(String groupId) async {
    await repository.cancelRequest(userId, groupId);
  }

  @override
  void dispose() {
    _groupsSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }
}
