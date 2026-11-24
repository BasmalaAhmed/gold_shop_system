import 'package:gold_shop_app/modules/auth_notification/features/notifications/domain/entities/approval_request.dart';

sealed class ApprovalState {
  const ApprovalState();
}

class ApprovalInitial extends ApprovalState {
  const ApprovalInitial();
}

class ApprovalLoading extends ApprovalState {
  const ApprovalLoading();
}

class ApprovalLoaded extends ApprovalState {
  final ApprovalRequest request;

  const ApprovalLoaded(this.request);
}

class ApprovalFailure extends ApprovalState {
  final String message;

  const ApprovalFailure(this.message);
}