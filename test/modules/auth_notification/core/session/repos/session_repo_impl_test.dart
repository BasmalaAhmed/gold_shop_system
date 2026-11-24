import 'dart:convert';

import 'package:gold_shop_app/modules/auth_notification/core/session/repos/session_repo_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_shop_app/modules/auth_notification/core/security/secure_storage_service.dart';
import 'package:gold_shop_app/modules/auth_notification/core/session/entities/session.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSecureStorageService mockStorage;
  late SessionRepoImpl repo;

  setUp(() {
    mockStorage = MockSecureStorageService();
    repo = SessionRepoImpl(mockStorage);
  });

  final session = Session(
    accessToken: 'access_123',
    refreshToken: 'refresh_123',
    expiresAt: DateTime(2026, 11, 21, 18),
  );

  test('saves session data in secure storage', () async {
    when(
      () => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});

    await repo.saveSession(session);

    final capturedData =
        verify(
              () => mockStorage.write(
                key: 'user_session',
                value: captureAny(named: 'value'),
              ),
            ).captured.single
            as String;

    final decodedData = jsonDecode(capturedData) as Map<String, dynamic>;

    expect(decodedData['access_token'], 'access_123');
    expect(decodedData['refresh_token'], 'refresh_123');
    expect(decodedData['expires_at'], session.expiresAt.toIso8601String());
  });

  test('returns session when valid session data exists', () async {
    final storedData = jsonEncode({
      'access_token': 'access_123',
      'refresh_token': 'refresh_123',
      'expires_at': session.expiresAt.toIso8601String(),
    });

    when(
      () => mockStorage.read(key: 'user_session'),
    ).thenAnswer((_) async => storedData);

    final result = await repo.getSession();

    expect(result, isNotNull);
    expect(result!.accessToken, session.accessToken);
    expect(result.refreshToken, session.refreshToken);
    expect(result.expiresAt, session.expiresAt);
  });

  test('clears session from secure storage', () async {
    when(
      () => mockStorage.delete(key: 'user_session'),
    ).thenAnswer((_) async {});

    await repo.clearSession();

    verify(() => mockStorage.delete(key: 'user_session')).called(1);
  });

  test('clears session when stored data is invalid JSON', () async {
    when(
      () => mockStorage.read(key: 'user_session'),
    ).thenAnswer((_) async => 'invalid_json');

    when(
      () => mockStorage.delete(key: 'user_session'),
    ).thenAnswer((_) async {});

    final result = await repo.getSession();

    expect(result, isNull);

    verify(() => mockStorage.delete(key: 'user_session')).called(1);
  });

  test('clears session when required fields are missing', () async {
  final storedData = jsonEncode({
    'access_token': 'access_123',
    'expires_at': session.expiresAt.toIso8601String(),
  });

  when(
    () => mockStorage.read(key: 'user_session'),
  ).thenAnswer((_) async => storedData);

  when(
    () => mockStorage.delete(key: 'user_session'),
  ).thenAnswer((_) async {});

  final result = await repo.getSession();

  expect(result, isNull);

  verify(
    () => mockStorage.delete(key: 'user_session'),
  ).called(1);
});

test('clears session when stored fields have invalid types', () async {
  final storedData = jsonEncode({
    'access_token': 12345,
    'refresh_token': 'refresh_123',
    'expires_at': session.expiresAt.toIso8601String(),
  });

  when(
    () => mockStorage.read(key: 'user_session'),
  ).thenAnswer((_) async => storedData);

  when(
    () => mockStorage.delete(key: 'user_session'),
  ).thenAnswer((_) async {});

  final result = await repo.getSession();

  expect(result, isNull);

  verify(
    () => mockStorage.delete(key: 'user_session'),
  ).called(1);
});
}
