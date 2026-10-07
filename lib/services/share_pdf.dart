import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

Rect? shareOriginOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Copies the PDF to a temp file with a readable Japanese name, then opens
/// the iOS share sheet. The temp copy stays until the OS clears it, because
/// the sheet may read the file after this method returns.
Future<void> sharePdf({
  required String path,
  required String fileName,
  required String subject,
  Rect? origin,
}) async {
  final directory = await Directory.systemTemp.createTemp('nippo_share_');
  final safeName = fileName.replaceAll(RegExp(r'[\\/]'), '_');
  final copy = File(p.join(directory.path, safeName));
  await File(path).copy(copy.path);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(copy.path, mimeType: 'application/pdf', name: safeName)],
      fileNameOverrides: [safeName],
      subject: subject,
      sharePositionOrigin: origin,
    ),
  );
}
