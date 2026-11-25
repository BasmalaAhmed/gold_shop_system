class MockSessionApi {
  static const _tokenPrefix = 'mock_refresh_token_';

  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (!refreshToken.startsWith(_tokenPrefix)) {
      throw Exception('Invalid refresh token');
    }

    final current =
        int.tryParse(refreshToken.substring(_tokenPrefix.length)) ?? 1;
    final next = (current + 1).toString().padLeft(3, '0');

    return {
      'access_token': 'mock_access_token_$next',
      'refresh_token': '$_tokenPrefix$next',
      'expires_at': DateTime.now()
          .add(const Duration(minutes: 15))
          .toIso8601String(),
    };
  }
}