String applyKey(String raw, String key) {
  if (key == 'back') {
    return raw.isEmpty ? raw : raw.substring(0, raw.length - 1);
  }

  if (key == '.') {
    if (raw.contains('.')) return raw;
    return raw.isEmpty ? '0.' : '$raw.';
  }
  if (raw == '0') return key;
  final dot = raw.indexOf('.');
  if (dot != -1 && raw.length - dot > 2) return raw;
  if (raw.length >= 9) return raw;
  return '$raw$key';
}
