String formatEgp(int piastres) {
  final isNegative = piastres < 0;
  final absolute = piastres.abs();
  final pounds = absolute ~/ 100;
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  final digits = pounds.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }

  final formattedPounds = '${isNegative ? '-' : ''}$buffer';

  return '$formattedPounds.$fraction ج.م';
}

int? parseEgpAmount(String input) {
  final normalized = input.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;

  final parts = normalized.split('.');
  if (parts.length > 2 || !RegExp(r'^\d+$').hasMatch(parts[0])) {
    return null;
  }

  var fraction = '';
  if (parts.length == 2) {
    fraction = parts[1];
    if (fraction.isNotEmpty && !RegExp(r'^\d{1,2}$').hasMatch(fraction)) {
      return null;
    }
  }

  final pounds = int.tryParse(parts[0]);
  final piastres = int.tryParse(fraction.padRight(2, '0'));
  if (pounds == null || piastres == null) return null;
  return pounds * 100 + piastres;
}

String piastresToRaw(int piastres) {
  final pounds = piastres ~/ 100;
  final rest = piastres % 100;
  return rest == 0 ? '$pounds' : '$pounds.${rest.toString().padLeft(2, '0')}';
}

String formatEgpNumber(int piastres) =>
    formatEgp(piastres).replaceAll(' ج.م', '');
