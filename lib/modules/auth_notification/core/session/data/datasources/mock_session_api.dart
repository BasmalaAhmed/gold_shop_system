class MockSessionApi {
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (refreshToken != 'mock_refresh_token_001') {
      throw Exception('Invalid refresh token');
    }

    return {
      'access_token': 'mock_access_token_002',
      'refresh_token': 'mock_refresh_token_002',
      'expires_at': DateTime.now()
          .add(const Duration(minutes: 15))
          .toIso8601String(),
    };
  }
}