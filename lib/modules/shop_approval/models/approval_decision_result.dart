import 'package:gold_shop_app/modules/shop_approval/models/approval_request.dart';

enum ApprovalDecisionOutcome { applied, versionConflict }

class ApprovalDecisionResult {
  final ApprovalRequest request;
  final ApprovalDecisionOutcome outcome;

  const ApprovalDecisionResult({required this.request, required this.outcome});
}
