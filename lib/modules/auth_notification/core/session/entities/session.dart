class Session {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }
}