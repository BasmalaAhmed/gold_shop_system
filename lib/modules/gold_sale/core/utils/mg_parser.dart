int? parseMgs(String value) {
  final input = value.trim();
  if (input.isEmpty) return null;

  final parts = input.split('.');
  if (parts.length > 2) return null;

  final whole = parts[0].isEmpty ? '0' : parts[0];
  final fraction = parts.length == 2 ? parts[1] : '';

  if (!RegExp(r'^\d+$').hasMatch(whole)) return null;
  if (fraction.length > 3 ||
      (fraction.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fraction))) {
    return null;
  }
  return int.parse(whole) * 1000 + int.parse(fraction.padRight(3, '0'));
}
