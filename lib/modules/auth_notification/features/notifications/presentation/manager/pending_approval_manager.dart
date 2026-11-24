class PendingApprovalManager {
  String? _pendingRequestId;

  String? get pendingRequestId => _pendingRequestId;

  bool get hasPendingRequest => _pendingRequestId != null;

  bool handleLink(Uri uri, {String? ignoredRequestId}) {
    if (uri.scheme != 'myapp' || uri.host != 'approval') {
      return false;
    }

    if (uri.pathSegments.length != 1) {
      return false;
    }

    final requestId = uri.pathSegments.first;

    if (requestId.isEmpty) {
      return false;
    }

    if (requestId == ignoredRequestId) {
      return false;
    }

    _pendingRequestId = requestId;
    return true;
  }

  void clearPendingRequest() {
    _pendingRequestId = null;
  }
}
