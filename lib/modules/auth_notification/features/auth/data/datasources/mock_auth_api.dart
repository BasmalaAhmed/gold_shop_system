class MockAuthApi {
  bool isCurrentDeviceNew = true;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (email != 'user@example.com' || password != 'Password123!') {
      throw Exception('Invalid email or password');
    }

    return {
      'challenge_id': 'challenge_001',
      'masked_destination': 'u***@example.com',
    };
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String challengeId,
    required String code,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (challengeId != 'challenge_001') {
      throw Exception('Invalid OTP challenge');
    }

    if (code != '123456' && code != '111111') {
      throw Exception('Invalid OTP code');
    }

    if (!isCurrentDeviceNew || code == '111111') {
      return {
        'status': 'success',
        'access_token': 'mock_access_token_001',
        'refresh_token': 'mock_refresh_token_001',
        'expires_at': DateTime.now()
            .add(const Duration(minutes: 15))
            .toIso8601String(),
      };
    }

    return {
      'status': 'device_verification_required',
      'challenge_id': 'device_001',
      'device_name': 'Windows Desktop',
    };
  }

  Future<Map<String, dynamic>> verifyDevice({
    required String challengeId,
    required String code,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (challengeId != 'device_001') {
      throw Exception('Invalid device challenge');
    }

    if (code != '654321') {
      throw Exception('Invalid device verification code');
    }

    isCurrentDeviceNew = false;

    return {
      'access_token': 'mock_access_token_001',
      'refresh_token': 'mock_refresh_token_001',
      'expires_at': DateTime.now()
          .add(const Duration(minutes: 15))
          .toIso8601String(),
    };
  }
}
