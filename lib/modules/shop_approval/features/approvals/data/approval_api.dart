import 'package:gold_shop_app/modules/shop_approval/models/approval_decision_command.dart';
import 'package:gold_shop_app/modules/shop_approval/models/approval_decision_result.dart';
import 'package:gold_shop_app/modules/shop_approval/models/approval_request.dart';

abstract class ApprovalApi {
  Future<List<ApprovalRequest>> fetchRequests();
  Future<void> cancelRequest(int requestId);
  Future<ApprovalRequest> createRequest({
    required String employeeName,
    required String branchName,
    required int amountInPiastres,
    required String reason,
    String? attentionMessage,
  });

  Future<ApprovalDecisionResult> submitDecision(
    ApprovalDecisionCommand command,
  );

  Future<ApprovalDecisionResult?> findDecisionById(String decisionId);
}
