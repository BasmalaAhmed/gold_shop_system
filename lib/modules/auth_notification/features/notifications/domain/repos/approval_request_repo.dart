import 'package:gold_shop_app/modules/auth_notification/features/notifications/domain/entities/approval_request.dart';

abstract class ApprovalRequestRepo {
  Future<ApprovalRequest> getApprovalRequest({
    required String requestId,
  });
}