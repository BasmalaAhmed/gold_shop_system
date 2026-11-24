import 'package:flutter_test/flutter_test.dart';
import 'package:gold_shop_app/modules/auth_notification/features/notifications/presentation/manager/pending_approval_manager.dart';

void main() {
  late PendingApprovalManager manager;

  setUp(() {
    manager = PendingApprovalManager();
  });

  group('PendingApprovalManager', () {
    test('stores request ID from a valid link', () {
      final result = manager.handleLink(
        Uri.parse('myapp://approval/request_001'),
      );

      expect(result, isTrue);
      expect(manager.hasPendingRequest, isTrue);
      expect(manager.pendingRequestId, 'request_001');
    });

    test('rejects an invalid scheme', () {
      final result = manager.handleLink(
        Uri.parse('https://approval/request_001'),
      );

      expect(result, isFalse);
      expect(manager.hasPendingRequest, isFalse);
    });

    test('rejects an invalid host', () {
      final result = manager.handleLink(
        Uri.parse('myapp://profile/request_001'),
      );

      expect(result, isFalse);
      expect(manager.hasPendingRequest, isFalse);
    });

    test('rejects a link without a request ID', () {
      final result = manager.handleLink(Uri.parse('myapp://approval'));

      expect(result, isFalse);
      expect(manager.hasPendingRequest, isFalse);
    });

    test(
      'does not lose the pending request when the same link is received again',
      () {
        manager.handleLink(Uri.parse('myapp://approval/request_001'));

        manager.handleLink(Uri.parse('myapp://approval/request_001'));

        expect(manager.pendingRequestId, 'request_001');
      },
    );

    test('clears the pending request', () {
      manager.handleLink(Uri.parse('myapp://approval/request_001'));

      manager.clearPendingRequest();

      expect(manager.hasPendingRequest, isFalse);
      expect(manager.pendingRequestId, isNull);
    });

    test('replaces pending request when a new valid link arrives', () {
      manager.handleLink(Uri.parse('myapp://approval/request_001'));

      final result = manager.handleLink(
        Uri.parse('myapp://approval/request_002'),
      );

      expect(result, isTrue);
      expect(manager.pendingRequestId, 'request_002');
    });

    test('rejects links with additional path segments', () {
      final result = manager.handleLink(
        Uri.parse('myapp://approval/request_001/extra'),
      );

      expect(result, isFalse);
      expect(manager.hasPendingRequest, isFalse);
    });

    test('preserves pending request when an invalid link is received', () {
      manager.handleLink(Uri.parse('myapp://approval/request_001'));

      final result = manager.handleLink(
        Uri.parse('https://approval/request_002'),
      );

      expect(result, isFalse);
      expect(manager.hasPendingRequest, isTrue);
      expect(manager.pendingRequestId, 'request_001');
    });

    test('uses only request ID and ignores query parameters', () {
      final result = manager.handleLink(
        Uri.parse(
          'myapp://approval/request_001?role=admin&permission=approved',
        ),
      );

      expect(result, isTrue);
      expect(manager.pendingRequestId, 'request_001');
    });
  });
}
