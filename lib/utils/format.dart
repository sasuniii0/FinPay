const currencyCode = 'LKR';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats an amount in cents, e.g. `24575000` -> `LKR 245,750.00`.
String formatMoney(int cents, {bool withCode = true}) {
  final negative = cents < 0;
  final abs = cents.abs();
  final digits = (abs ~/ 100).toString();
  final fraction = (abs % 100).toString().padLeft(2, '0');

  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
    grouped.write(digits[i]);
  }

  final prefix = withCode ? '$currencyCode ' : '';
  return '${negative ? '-' : ''}$prefix$grouped.$fraction';
}

/// Parses user input such as `1,250.5` into cents. Returns null when invalid.
int? parseAmountToCents(String input) {
  final cleaned = input.replaceAll(',', '').trim();
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(cleaned)) return null;

  final parts = cleaned.split('.');
  final whole = int.parse(parts[0]);
  final fraction = parts.length > 1 ? int.parse(parts[1].padRight(2, '0')) : 0;
  return whole * 100 + fraction;
}

String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String formatTime(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  return '${hour.toString().padLeft(2, '0')}:$minute ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "Today", "Yesterday" or a full date.
String formatDay(DateTime d, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final diff = today.difference(_dateOnly(d)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return formatDate(d);
}

String formatDayTime(DateTime d) {
  final day = formatDay(d);
  return day == 'Today' || day == 'Yesterday' ? '$day, ${formatTime(d)}' : day;
}

String maskAccount(String number) =>
    '**** ${number.substring(number.length - 4)}';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
