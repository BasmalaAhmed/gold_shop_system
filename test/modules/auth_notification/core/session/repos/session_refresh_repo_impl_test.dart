import 'package:gold_shop_app/modules/auth_notification/core/session/data/repos/session_refresh_repo_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/data/datasources/mock_session_api.dart';

class MockSessionApiMock extends Mock implements MockSessionApi {}

void main() {
  late MockSessionApiMock mockApi;
  late SessionRefreshRepoImpl repo;

  setUp(() {
    mockApi = MockSessionApiMock();
    repo = SessionRefreshRepoImpl(mockApi);
  });

  test('returns new session when refresh succeeds', () async {
    final expiresAt = DateTime.now().add(
      const Duration(minutes: 15),
    );

    when(
      () => mockApi.refreshToken(
        refreshToken: 'mock_refresh_token_001',
      ),
    ).thenAnswer(
      (_) async => {
        'access_token': 'mock_access_token_002',
        'refresh_token': 'mock_refresh_token_002',
        'expires_at': expiresAt.toIso8601String(),
      },
    );

    final result = await repo.refreshSession(
      refreshToken: 'mock_refresh_token_001',
    );

    expect(result.accessToken, 'mock_access_token_002');
    expect(result.refreshToken, 'mock_refresh_token_002');
    expect(result.expiresAt, expiresAt);

    verify(
      () => mockApi.refreshToken(
        refreshToken: 'mock_refresh_token_001',
      ),
    ).called(1);
  });
}