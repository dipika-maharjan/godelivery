import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Shares plain text (e.g. a tracking link) via the OS share sheet.
Future<void> shareText(String text, {String? subject}) {
  return SharePlus.instance.share(ShareParams(text: text, subject: subject));
}

/// Captures whatever is under [boundaryKey] (a [RepaintBoundary]'s key) as a
/// PNG and shares it as an image, optionally with [text]/[subject].
Future<void> shareWidgetSnapshot(
  GlobalKey boundaryKey, {
  String fileName = 'snapshot.png',
  String? text,
  String? subject,
}) async {
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return;

  final image = await boundary.toImage(pixelRatio: 3.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return;
  final bytes = byteData.buffer.asUint8List();

  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);

  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: text, subject: subject),
  );
}
