import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../core/network/api_exception.dart';

/// Views a PDF fetched on demand, with built-in share/print actions
/// (from the `printing` package's [PdfPreview]).
class PdfViewerPage extends StatelessWidget {
  const PdfViewerPage({
    super.key,
    required this.title,
    required this.fileName,
    required this.loadBytes,
  });

  final String title;
  final String fileName;
  final Future<Uint8List> Function() loadBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        build: (format) => loadBytes(),
        pdfFileName: fileName,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        onError: (context, error) => Center(
          child: Text(
            error is ApiException ? error.message : 'Could not load the PDF.',
          ),
        ),
      ),
    );
  }
}
