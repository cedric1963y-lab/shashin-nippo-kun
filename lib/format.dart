const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

DateTime dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day, 12);
}

bool isSameDay(DateTime a, DateTime b) {
  final left = a.toLocal();
  final right = b.toLocal();
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String formatJapaneseDate(DateTime value) {
  final local = value.toLocal();
  final weekday = _weekdays[local.weekday - 1];
  return '${local.year}年${local.month}月${local.day}日（$weekday）';
}

String formatShortDate(DateTime value) {
  final local = value.toLocal();
  final weekday = _weekdays[local.weekday - 1];
  return '${local.month}/${local.day}（$weekday）';
}

String formatTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// The pdf package wraps on spaces. Japanese has none, so break onto
/// explicit lines. Zero-width spaces are not in the embedded font.
String breakForPdf(String input, {int columns = 28}) {
  if (input.isEmpty || columns < 1) return input;
  final runes = input.runes.toList();
  final buffer = StringBuffer();
  for (var i = 0; i < runes.length; i++) {
    if (i > 0 && i % columns == 0) buffer.write('\n');
    buffer.writeCharCode(runes[i]);
  }
  return buffer.toString();
}

String collapseWhitespace(String input) {
  return input.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String reportShareFileName({
  required String siteName,
  required DateTime reportDate,
}) {
  final cleaned = siteName.replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), '').trim();
  final clipped = cleaned.isEmpty
      ? '現場'
      : (cleaned.length > 24 ? cleaned.substring(0, 24) : cleaned);
  final local = reportDate.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '写真日報_${clipped}_$y$m$d.pdf';
}

/// EXIF `DateTimeOriginal`, for example `2024:05:01 08:30:00`.
DateTime? parseExifDate(String raw) {
  final match = RegExp(r'(\d{4}):(\d{2}):(\d{2})[ T](\d{2}):(\d{2}):(\d{2})')
      .firstMatch(raw.trim());
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.parse(match.group(6)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  if (hour > 23 || minute > 59 || second > 59) return null;
  return DateTime(year, month, day, hour, minute, second);
}
