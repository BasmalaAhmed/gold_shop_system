import 'package:gold_shop_app/modules/auth_notification/core/api/api_request_executor.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/data/datasources/mock_approval_api.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/domain/entities/approval_request.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/domain/repos/approval_request_repo.dart';

class ApprovalRequestRepoImpl implements ApprovalRequestRepo {
  final MockApprovalApi mockApprovalApi;
  final ApiRequestExecutor apiRequestExecutor;

  ApprovalRequestRepoImpl(
    this.mockApprovalApi,
    this.apiRequestExecutor,
  );

  @override
  Future<ApprovalRequest> getApprovalRequest({
    required String requestId,
  }) async {
    final response = await apiRequestExecutor.execute(
      request: (accessToken) {
        return mockApprovalApi.getApprovalRequest(
          accessToken: accessToken,
          requestId: requestId,
        );
      },
    );

    return ApprovalRequest(
      requestId: response['request_id'] as String,
      title: response['title'] as String,
      description: response['description'] as String,
    );
  }
}