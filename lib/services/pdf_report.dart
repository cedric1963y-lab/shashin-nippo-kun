import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../format.dart';

class PdfPhoto {
  const PdfPhoto({
    required this.bytes,
    required this.memo,
    required this.takenAt,
  });

  final Uint8List bytes;
  final String memo;
  final DateTime takenAt;
}

const _slate = PdfColor.fromInt(0xFF28425D);
const _orange = PdfColor.fromInt(0xFFE85D04);
const _ink = PdfColor.fromInt(0xFF1C1917);
const _muted = PdfColor.fromInt(0xFF5E584F);
const _line = PdfColor.fromInt(0xFFE4DDD2);
const _photoWell = PdfColor.fromInt(0xFFF7F4EE);

/// Builds one A4 daily report. The embedded font is subset to the glyphs used.
Future<Uint8List> buildDailyReportPdf({
  required ByteData fontData,
  required String siteName,
  required String siteNote,
  required DateTime reportDate,
  required String summary,
  required List<PdfPhoto> photos,
}) async {
  if (photos.isEmpty) {
    throw ArgumentError('photos must not be empty');
  }

  final font = pw.Font.ttf(fontData);
  final theme = pw.ThemeData.withFont(
    base: font,
    bold: font,
    italic: font,
    boldItalic: font,
  );
  final document = pw.Document(
    title: '写真日報 $siteName',
    author: '写真日報くん',
    creator: '写真日報くん',
    theme: theme,
  );

  const perPage = 2;
  final pageCount = (photos.length / perPage).ceil();
  for (var page = 0; page < pageCount; page++) {
    final slice = photos.skip(page * perPage).take(perPage).toList();
    final firstPage = page == 0;
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: theme,
        build: (context) {
          return pw.Column(
            children: [
              _header(reportDate),
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(28, 16, 28, 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (firstPage) _intro(siteName, siteNote, summary),
                    for (final photo in slice)
                      _photoBlock(
                        photo,
                        height: _imageHeight(
                          firstPage: firstPage,
                          onPage: slice.length,
                          summary: firstPage ? summary : '',
                        ),
                      ),
                  ],
                ),
              ),
              pw.Spacer(),
              _footer(page + 1, pageCount),
            ],
          );
        },
      ),
    );
  }

  return document.save();
}

double _imageHeight({
  required bool firstPage,
  required int onPage,
  required String summary,
}) {
  if (onPage == 1) return firstPage ? 430.0 : 500.0;
  final summaryPenalty = summary.length > 40 ? 24.0 : 0.0;
  return (firstPage ? 214.0 : 268.0) - summaryPenalty;
}

pw.Widget _header(DateTime reportDate) {
  return pw.Column(
    children: [
      pw.Container(
        height: 72,
        color: _slate,
        padding: const pw.EdgeInsets.fromLTRB(28, 18, 28, 14),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  '写真日報',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '写真日報くん',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            pw.Text(
              breakForPdf(formatJapaneseDate(reportDate)),
              style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
            ),
          ],
        ),
      ),
      pw.Container(height: 4, color: _orange),
    ],
  );
}

pw.Widget _intro(String siteName, String siteNote, String summary) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('現場', style: const pw.TextStyle(color: _muted, fontSize: 9)),
      pw.SizedBox(height: 2),
      pw.Text(
        breakForPdf(siteName),
        style: pw.TextStyle(
          color: _ink,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      if (siteNote.trim().isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Text(
          breakForPdf(siteNote.trim()),
          style: const pw.TextStyle(color: _muted, fontSize: 10),
        ),
      ],
      if (summary.trim().isNotEmpty) ...[
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _photoWell,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            breakForPdf(summary.trim()),
            style: const pw.TextStyle(
              color: _ink,
              fontSize: 11,
              lineSpacing: 2,
            ),
          ),
        ),
      ],
      pw.SizedBox(height: 12),
    ],
  );
}

pw.Widget _photoBlock(PdfPhoto photo, {required double height}) {
  final memo = photo.memo.trim();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 12),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: height,
          width: double.infinity,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: _photoWell,
            border: pw.Border.all(color: _line, width: 0.8),
          ),
          child: pw.Image(
            pw.MemoryImage(photo.bytes),
            fit: pw.BoxFit.contain,
            height: height - 2,
            width: 539,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              formatTime(photo.takenAt),
              style: pw.TextStyle(
                color: _orange,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Text(
                memo.isEmpty ? 'メモなし' : breakForPdf(memo),
                style: pw.TextStyle(
                  color: memo.isEmpty ? _muted : _ink,
                  fontSize: 11,
                  lineSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _footer(int page, int pageCount) {
  return pw.Container(
    height: 32,
    padding: const pw.EdgeInsets.symmetric(horizontal: 28),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _line, width: 0.6)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'このPDFはiPhoneの中で作成されました',
          style: const pw.TextStyle(color: _muted, fontSize: 8),
        ),
        pw.Text(
          '$page / $pageCount',
          style: const pw.TextStyle(color: _muted, fontSize: 8),
        ),
      ],
    ),
  );
}
