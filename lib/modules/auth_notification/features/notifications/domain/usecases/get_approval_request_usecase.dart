import 'package:gold_shop_app/modules/auth_notification/features/notifications/domain/entities/approval_request.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/domain/repos/approval_request_repo.dart';

class GetApprovalRequestUseCase {
  final ApprovalRequestRepo approvalRequestRepo;

  GetApprovalRequestUseCase(this.approvalRequestRepo);

  Future<ApprovalRequest> call({
    required String requestId,
  }) {
    return approvalRequestRepo.getApprovalRequest(
      requestId: requestId,
    );
  }
}