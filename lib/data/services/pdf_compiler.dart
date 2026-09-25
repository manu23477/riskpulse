import 'dart:io' as io;
import 'dart:convert' as convert;
import 'package:flutter/foundation.dart';

/// Pure Dart PDF 1.4 Compiler that generates structurally valid binary PDF documents.
///
/// DEPENDENCY-FREE & CROSS-PLATFORM:
/// Generates standard PDF 1.4 binary files with catalog, page tree, Helvetica fonts,
/// page headers, running footers, line-wrapped text streams, and valid cross-reference tables (xref).
class PdfCompiler {
  static const double pageWidth = 612.0; // Standard Letter width in points
  static const double pageHeight = 792.0; // Standard Letter height in points
  static const double margin = 36.0;
  static const double contentWidth = pageWidth - (margin * 2); // 540 pt
  static const double topMargin = 54.0;
  static const double bottomMargin = 54.0;
  static const double contentHeight = pageHeight - topMargin - bottomMargin; // 684 pt

  const PdfCompiler();

  /// Compiles markdown text into a binary PDF document.
  List<int> compileMarkdownToPdf({
    required String documentTitle,
    required String subtitle,
    required String markdownContent,
    double? customWidth,
    double? customHeight,
  }) {
    final double pWidth = customWidth ?? pageWidth;
    final double pHeight = customHeight ?? pageHeight;
    final double cHeight = pHeight - topMargin - bottomMargin;

    final List<String> lines = markdownContent.split('\n');
    final List<List<String>> pagesLines = [];
    List<String> currentPage = [];
    double currentY = 0.0;

    for (var rawLine in lines) {
      final line = rawLine.trimRight();
      double lineHeight = 14.0;

      if (line.startsWith('# ')) {
        lineHeight = 24.0;
      } else if (line.startsWith('## ')) {
        lineHeight = 20.0;
      } else if (line.startsWith('### ')) {
        lineHeight = 16.0;
      } else if (line.trim().isEmpty) {
        lineHeight = 8.0;
      }

      // Line wrapping for long body text
      final wrapped = _wrapLine(line, (pWidth / 7.5).round());
      for (var wLine in wrapped) {
        if (currentY + lineHeight > cHeight) {
          pagesLines.add(currentPage);
          currentPage = [];
          currentY = 0.0;
        }
        currentPage.add(wLine);
        currentY += lineHeight;
      }
    }

    if (currentPage.isNotEmpty) {
      pagesLines.add(currentPage);
    }

    if (pagesLines.isEmpty) {
      pagesLines.add(['# $documentTitle', subtitle]);
    }

    return _generatePdfBinary(
      documentTitle: documentTitle,
      subtitle: subtitle,
      pagesLines: pagesLines,
      customWidth: pWidth,
      customHeight: pHeight,
    );
  }

  /// Wraps long text lines to fit printable width (~80 chars).
  List<String> _wrapLine(String line, int maxChars) {
    if (line.length <= maxChars || line.startsWith('#')) return [line];

    final List<String> result = [];
    final words = line.split(' ');
    var current = '';

    for (var word in words) {
      if ((current + ' ' + word).trim().length <= maxChars) {
        current = (current + ' ' + word).trim();
      } else {
        if (current.isNotEmpty) result.add(current);
        current = word;
      }
    }
    if (current.isNotEmpty) result.add(current);
    return result;
  }

  /// Synthesizes binary PDF 1.4 stream structure.
  List<int> _generatePdfBinary({
    required String documentTitle,
    required String subtitle,
    required List<List<String>> pagesLines,
    double? customWidth,
    double? customHeight,
  }) {
    final double pWidth = customWidth ?? pageWidth;
    final double pHeight = customHeight ?? pageHeight;

    final totalPages = pagesLines.length;
    final List<int> pdfBytes = [];
    final List<int> offsets = [0]; // Object 0 is dummy

    void writeString(String str) {
      pdfBytes.addAll(convert.utf8.encode(str));
    }

    void writeObject(int id, String content) {
      offsets.add(pdfBytes.length);
      writeString('$id 0 obj\n$content\nendobj\n');
    }

    // PDF Header
    writeString('%PDF-1.4\n%\xFF\xFF\xFF\xFF\n');

    // Object 1: Catalog
    writeObject(1, '<< /Type /Catalog /Pages 2 0 R >>');

    // Object 2: Pages (Kids array dynamically built)
    final kidsReferences = List.generate(totalPages, (i) => '${5 + (i * 2)} 0 R').join(' ');
    writeObject(2, '<< /Type /Pages /Count $totalPages /Kids [ $kidsReferences ] >>');

    // Object 3: Font Helvetica Regular
    writeObject(3, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>');

    // Object 4: Font Helvetica Bold
    writeObject(4, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>');

    // Generate Page Objects & Content Streams
    for (int p = 0; p < totalPages; p++) {
      final pageObjId = 5 + (p * 2);
      final streamObjId = pageObjId + 1;

      // Page Object
      writeObject(
        pageObjId,
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $pWidth $pHeight] '
        '/Contents $streamObjId 0 R '
        '/Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> >>',
      );

      // Stream Content
      final streamBuffer = StringBuffer();

      // Header Banner
      streamBuffer.writeln('BT /F2 8 Tf 36 ${pHeight - 28} Td (${_escapePdf(documentTitle.toUpperCase())}) Tj ET');
      streamBuffer.writeln('BT /F1 8 Tf ${pWidth - 140} ${pHeight - 28} Td (RiskPulse v1.0.0+1) Tj ET');
      streamBuffer.writeln('0.5 w 36 ${pHeight - 34} m ${pWidth - 36} ${pHeight - 34} l S');

      // Running Footer
      streamBuffer.writeln('0.5 w 36 36 m ${pWidth - 36} 36 l S');
      streamBuffer.writeln('BT /F1 8 Tf 36 24 Td (Confidential Research Documentation — Association does NOT establish causation) Tj ET');
      streamBuffer.writeln('BT /F2 8 Tf ${pWidth - 90} 24 Td (Page ${p + 1} of $totalPages) Tj ET');

      // Body Text Lines
      double y = pHeight - topMargin - 12.0;

      for (var line in pagesLines[p]) {
        if (line.startsWith('# ')) {
          final clean = line.substring(2).trim();
          streamBuffer.writeln('BT /F2 16 Tf $margin $y Td (${_escapePdf(clean)}) Tj ET');
          y -= 22.0;
        } else if (line.startsWith('## ')) {
          final clean = line.substring(3).trim();
          streamBuffer.writeln('BT /F2 13 Tf $margin $y Td (${_escapePdf(clean)}) Tj ET');
          y -= 18.0;
        } else if (line.startsWith('### ')) {
          final clean = line.substring(4).trim();
          streamBuffer.writeln('BT /F2 10 Tf $margin $y Td (${_escapePdf(clean)}) Tj ET');
          y -= 15.0;
        } else if (line.startsWith('> ')) {
          final clean = line.substring(2).trim();
          streamBuffer.writeln('BT /F2 9 Tf ${margin + 10} $y Td (${_escapePdf(clean)}) Tj ET');
          y -= 13.0;
        } else if (line.trim().isEmpty) {
          y -= 8.0;
        } else {
          streamBuffer.writeln('BT /F1 9 Tf $margin $y Td (${_escapePdf(line.trim())}) Tj ET');
          y -= 12.0;
        }
      }

      final streamBytes = convert.utf8.encode(streamBuffer.toString());
      writeObject(streamObjId, '<< /Length ${streamBytes.length} >>\nstream\n${streamBuffer.toString()}endstream');
    }

    // Cross-Reference Table
    final startXref = pdfBytes.length;
    final totalObjects = 4 + (totalPages * 2) + 1;

    writeString('xref\n0 $totalObjects\n0000000000 65535 f \n');
    for (int i = 1; i < totalObjects; i++) {
      final offsetStr = offsets[i].toString().padLeft(10, '0');
      writeString('$offsetStr 00000 n \n');
    }

    // Trailer
    writeString('trailer\n<< /Size $totalObjects /Root 1 0 R >>\nstartxref\n$startXref\n%%EOF\n');

    return pdfBytes;
  }

  String _escapePdf(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)')
        .replaceAll('\r', '')
        .replaceAll('\n', ' ');
  }

  /// Compiles markdown and writes a real PDF binary file to [targetPdfPath].
  bool compileAndSavePdf({
    required String documentTitle,
    required String subtitle,
    required String markdownContent,
    required String targetPdfPath,
    double? customWidth,
    double? customHeight,
  }) {
    try {
      final pdfBytes = compileMarkdownToPdf(
        documentTitle: documentTitle,
        subtitle: subtitle,
        markdownContent: markdownContent,
        customWidth: customWidth,
        customHeight: customHeight,
      );

      final file = io.File(targetPdfPath);
      final parentDir = file.parent;
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }

      file.writeAsBytesSync(pdfBytes);
      return file.existsSync() && file.lengthSync() > 0;
    } catch (e) {
      if (kDebugMode) {
        print('PdfCompiler error writing PDF to $targetPdfPath: $e');
      }
      return false;
    }
  }
}
