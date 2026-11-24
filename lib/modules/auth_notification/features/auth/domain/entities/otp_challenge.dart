class OtpChallenge {
  final String challengeId;
  final String maskedDestination;

  const OtpChallenge({
    required this.challengeId,
    required this.maskedDestination,
  });
}