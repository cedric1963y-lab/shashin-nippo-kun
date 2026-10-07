import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shashin_nippo/services/pdf_report.dart';

import 'support/harness.dart';

void main() {
  test('builds a multi-page Japanese report', () async {
    final font = await loadTestFont();
    final photo = tinyJpeg(width: 80, height: 60);
    final memo = '外壁下地完了明日塗装北側足場解体' * 4;
    final bytes = await buildDailyReportPdf(
      fontData: font,
      siteName: '南青山リフォーム',
      siteNote: '元請 山田工務店',
      reportDate: DateTime(2026, 10, 7, 12),
      summary: '外壁下地まで。明日塗装。',
      photos: [
        for (var i = 0; i < 3; i++)
          PdfPhoto(
            bytes: photo,
            memo: memo,
            takenAt: DateTime(2026, 10, 7, 8 + i, 15),
          ),
      ],
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(3000));
    expect(bytes.length, lessThan(1500000));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('refuses an empty photo list', () async {
    final font = ByteData(0);
    expect(
      () => buildDailyReportPdf(
        fontData: font,
        siteName: '現場',
        siteNote: '',
        reportDate: DateTime(2026, 10, 7),
        summary: '',
        photos: const [],
      ),
      throwsArgumentError,
    );
  });
}
