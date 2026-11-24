import 'package:gold_shop_app/modules/auth_notification/core/errors/api_exception.dart';

class MockApprovalApi {
  Future<Map<String, dynamic>> getApprovalRequest({
    required String accessToken,
    required String requestId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (accessToken != 'mock_access_token_001' &&
        accessToken != 'mock_access_token_002') {
      throw const ApiException(
        statusCode: 401,
        message: 'غير مصرح به',
      );
    }

    if (requestId == 'request_forbidden_001') {
      throw const ApiException(
        statusCode: 403,
        message: 'غير مسموح لك بالوصول إلى هذا الطلب.',
      );
    }

    if (requestId != 'request_001') {
      throw const ApiException(
        statusCode: 404,
        message: 'لم يتم العثور على طلب الموافقة.',
      );
    }

    return {
      'request_id': 'request_001',
      'title': 'الموافقة على متجر جديد',
      'description': 'متجر جديد بانتظار موافقتك.',
    };
  }
}