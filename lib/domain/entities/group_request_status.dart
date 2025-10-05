enum GroupRequestStatus { none, pending, approved }

GroupRequestStatus statusFromString(String? value) {
  switch (value) {
    case 'approved':
      return GroupRequestStatus.approved;
    case 'pending':
      return GroupRequestStatus.pending;
    default:
      return GroupRequestStatus.none;
  }
}

String statusToString(GroupRequestStatus status) {
  switch (status) {
    case GroupRequestStatus.pending:
      return 'pending';
    case GroupRequestStatus.approved:
      return 'approved';
    case GroupRequestStatus.none:
    default:
      return 'none';
  }
}
