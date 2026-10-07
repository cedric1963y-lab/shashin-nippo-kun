import 'package:flutter_test/flutter_test.dart';
import 'package:shashin_nippo/format.dart';

void main() {
  test('formats a Japanese date and time', () {
    final value = DateTime(2026, 10, 7, 9, 5);
    expect(formatJapaneseDate(value), '2026年10月7日（水）');
    expect(formatShortDate(value), '10/7（水）');
    expect(formatTime(value), '09:05');
    expect(isSameDay(value, DateTime(2026, 10, 7, 23, 59)), isTrue);
    expect(isSameDay(value, DateTime(2026, 10, 8)), isFalse);
  });

  test('parses EXIF timestamps and rejects junk', () {
    expect(parseExifDate('2024:05:01 08:30:00'), DateTime(2024, 5, 1, 8, 30));
    expect(parseExifDate('not a date'), isNull);
    expect(parseExifDate('2024:13:01 08:30:00'), isNull);
  });

  test('share file name drops path characters', () {
    expect(
      reportShareFileName(
        siteName: '南/青山:現場',
        reportDate: DateTime(2026, 1, 2),
      ),
      '写真日報_南青山現場_20260102.pdf',
    );
    expect(
      reportShareFileName(siteName: '   ', reportDate: DateTime(2026, 1, 2)),
      '写真日報_現場_20260102.pdf',
    );
  });

  test('pdf line breaking splits long Japanese without a special glyph', () {
    const memo = '外壁下地完了明日塗装';
    final wrapped = breakForPdf(memo, columns: 4);
    expect(wrapped, '外壁下地\n完了明日\n塗装');
    expect(wrapped.contains('\u200B'), isFalse);
  });
}
