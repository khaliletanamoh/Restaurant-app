String etb(num value) => '${value.round()} ETB';

String _two(int n) => n.toString().padLeft(2, '0');

String formatDateTime(DateTime date) {
  final d = date.toLocal();
  return '${d.year}-${_two(d.month)}-${_two(d.day)}  ${_two(d.hour)}:${_two(d.minute)}';
}

String shortId(String id) => id.length <= 5 ? id.toUpperCase() : id.substring(0, 5).toUpperCase();

/// Day key in Addis Ababa time (UTC+3, no daylight saving). Must match functions/index.js.
String addisDateKey([DateTime? now]) {
  final t = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 3));
  return '${t.year}-${_two(t.month)}-${_two(t.day)}';
}

/// Accepts 0911234567, 911234567, 251911234567, +251 911 234 567 (Ethio Telecom 09, Safaricom 07).
/// Returns +2519XXXXXXXX or null when invalid.
String? normalizeEthiopianPhone(String input) {
  var d = input.replaceAll(RegExp(r'[\s-]'), '');
  if (d.startsWith('+251')) {
    d = d.substring(4);
  } else if (d.startsWith('251')) {
    d = d.substring(3);
  } else if (d.startsWith('0')) {
    d = d.substring(1);
  }
  return RegExp(r'^[79]\d{8}$').hasMatch(d) ? '+251$d' : null;
}
