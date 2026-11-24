int? parsePiasters(String value) {
  final input = value.trim();
  if (input.isEmpty) return null;

  final parts = input.split('.');
  if (parts.length > 2) return null;

  final wholePart = parts[0].isEmpty ? '0' : parts[0];
  final fractionPart = parts.length == 2 ? parts[1] : '';

  if (!RegExp(r'^\d+$').hasMatch(wholePart)) return null;
  if (fractionPart.length > 2 ||
      (fractionPart.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fractionPart))) {
    return null;
  }

  final pounds = int.tryParse(wholePart);
  final piasters = int.tryParse(fractionPart.padRight(2, '0'));

  if (pounds == null || piasters == null) return null;

  return pounds * 100 + piasters;
}