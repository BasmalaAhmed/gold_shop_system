import 'package:gold_shop_app/modules/shop_approval/core/formatters.dart';
import 'package:gold_shop_app/modules/shop_approval/models/approval_decision.dart';
import 'package:gold_shop_app/modules/shop_approval/models/approval_request.dart';

extension ApprovalRequestPresentation on ApprovalRequest {
  bool get hasAttention => attentionMessage?.trim().isNotEmpty == true;

  bool get isPending => status == ApprovalStatus.pending;

  bool get wasRejected =>
      status == ApprovalStatus.rejected ||
      
          lastDecision == ApprovalDecision.reject;

  String get formattedAmount => formatPiastres(amountInPiastres);
}
