import 'dart:io' as io;
import 'dart:convert' as convert;
import 'package:flutter/foundation.dart';

/// Pure Dart PDF 1.4 Compiler that generates structurally valid binary PDF documents
/// complete with embedded high-resolution GIS map canvas images, cartographic vector
/// symbols, visual legend color ramps, and WinAnsi Unicode sanitization.
///
/// DEPENDENCY-FREE & CROSS-PLATFORM:
/// Generates standard PDF 1.4 binary files with catalog, page tree, Helvetica fonts,
/// image XObjects (/Type /XObject /Subtype /Image), page headers, running footers,
/// vector legend blocks, and valid cross-reference tables (xref).
class PdfCompiler {
  static const double pageWidth = 612.0; // Standard Letter width in points
  static const double pageHeight = 792.0; // Standard Letter height in points
  static const double margin = 36.0;
  static const double contentWidth = pageWidth - (margin * 2); // 540 pt
  static const double topMargin = 54.0;
  static const double bottomMargin = 54.0;
  static const double contentHeight = pageHeight - topMargin - bottomMargin; // 684 pt

  const PdfCompiler();

  /// Compiles markdown text and optional map canvas RGB image bytes into a publication PDF.
  List<int> compileMarkdownToPdf({
    required String documentTitle,
    required String subtitle,
    required String markdownContent,
    double? customWidth,
    double? customHeight,
    List<int>? mapRgbBytes,
    int? mapImageWidth,
    int? mapImageHeight,
  }) {
    final double pWidth = customWidth ?? pageWidth;
    final double pHeight = customHeight ?? pageHeight;
    final double cHeight = pHeight - topMargin - bottomMargin;

    final List<String> lines = markdownContent.split('\n');
    final List<List<String>> pagesLines = [];
    List<String> currentPage = [];
    double currentY = 0.0;

    // Reserve space for Page 1 Map Canvas if image bytes provided
    if (mapRgbBytes != null && mapImageWidth != null && mapImageHeight != null && mapImageWidth > 0 && mapImageHeight > 0) {
      final double targetW = pWidth - (margin * 2);
      final double aspect = mapImageHeight / mapImageWidth;
      final double targetH = (targetW * aspect).clamp(180.0, pHeight * 0.45);
      currentY += (targetH + 20.0); // Offset Page 1 text below map image
    }

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
      mapRgbBytes: mapRgbBytes,
      mapImageWidth: mapImageWidth,
      mapImageHeight: mapImageHeight,
    );
  }

  /// Wraps long text lines to fit printable width.
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

  /// Synthesizes binary PDF 1.4 stream structure with XObject image embedding and vector legend boxes.
  List<int> _generatePdfBinary({
    required String documentTitle,
    required String subtitle,
    required List<List<String>> pagesLines,
    double? customWidth,
    double? customHeight,
    List<int>? mapRgbBytes,
    int? mapImageWidth,
    int? mapImageHeight,
  }) {
    final double pWidth = customWidth ?? pageWidth;
    final double pHeight = customHeight ?? pageHeight;

    final totalPages = pagesLines.length;
    final List<int> pdfBytes = [];
    final List<int> offsets = [0]; // Object 0 is dummy

    final bool hasImage = mapRgbBytes != null &&
        mapImageWidth != null &&
        mapImageHeight != null &&
        mapImageWidth > 0 &&
        mapImageHeight > 0;

    void writeString(String str) {
      pdfBytes.addAll(convert.utf8.encode(str));
    }

    void writeBinaryObject(int id, String header, List<int> body, String footer) {
      offsets.add(pdfBytes.length);
      writeString('$id 0 obj\n$header\n');
      pdfBytes.addAll(body);
      writeString('\n$footer\nendobj\n');
    }

    void writeObject(int id, String content) {
      offsets.add(pdfBytes.length);
      writeString('$id 0 obj\n$content\nendobj\n');
    }

    // PDF Header
    writeString('%PDF-1.4\n%\xFF\xFF\xFF\xFF\n');

    // Object 1: Catalog
    writeObject(1, '<< /Type /Catalog /Pages 2 0 R >>');

    // Determine Object IDs
    int currentObjId = 5;
    int? imageObjId;

    if (hasImage) {
      imageObjId = currentObjId++;
    }

    // Object 2: Pages (Kids array dynamically built)
    final List<String> kidsRefs = [];
    final Map<int, int> pageObjIds = {};
    final Map<int, int> streamObjIds = {};

    for (int p = 0; p < totalPages; p++) {
      final pId = currentObjId++;
      final sId = currentObjId++;
      pageObjIds[p] = pId;
      streamObjIds[p] = sId;
      kidsRefs.add('$pId 0 R');
    }

    writeObject(2, '<< /Type /Pages /Count $totalPages /Kids [ ${kidsRefs.join(' ')} ] >>');

    // Object 3: Font Helvetica Regular
    writeObject(3, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>');

    // Object 4: Font Helvetica Bold
    writeObject(4, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>');

    // Object 5 (Optional): Image XObject
    if (hasImage && imageObjId != null) {
      final compressedBytes = io.zlib.encode(mapRgbBytes);
      final imageHeader = '<< /Type /XObject /Subtype /Image '
          '/Width $mapImageWidth /Height $mapImageHeight '
          '/ColorSpace /DeviceRGB /BitsPerComponent 8 '
          '/Filter /FlateDecode /Length ${compressedBytes.length} >>\nstream';
      writeBinaryObject(imageObjId, imageHeader, compressedBytes, 'endstream');
    }

    // Generate Page Objects & Content Streams
    for (int p = 0; p < totalPages; p++) {
      final pageObjId = pageObjIds[p]!;
      final streamObjId = streamObjIds[p]!;

      final String resourcesDict = hasImage && imageObjId != null
          ? '/Resources << /Font << /F1 3 0 R /F2 4 0 R >> /XObject << /Im1 $imageObjId 0 R >> >>'
          : '/Resources << /Font << /F1 3 0 R /F2 4 0 R >> >>';

      // Page Object
      writeObject(
        pageObjId,
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $pWidth $pHeight] '
        '/Contents $streamObjId 0 R '
        '$resourcesDict >>',
      );

      // Stream Content
      final streamBuffer = StringBuffer();

      // Header Banner
      streamBuffer.writeln('BT /F2 8 Tf 36 ${pHeight - 28} Td (${_sanitizePdfText(documentTitle.toUpperCase())}) Tj ET');
      streamBuffer.writeln('BT /F1 8 Tf ${pWidth - 140} ${pHeight - 28} Td (RiskPulse v1.0.0+1) Tj ET');
      streamBuffer.writeln('0.5 w 36 ${pHeight - 34} m ${pWidth - 36} ${pHeight - 34} l S');

      // Running Footer
      streamBuffer.writeln('0.5 w 36 36 m ${pWidth - 36} 36 l S');
      streamBuffer.writeln('BT /F1 8 Tf 36 24 Td (Confidential Research GIS Publication Map - Association does NOT establish causation) Tj ET');
      streamBuffer.writeln('BT /F2 8 Tf ${pWidth - 90} 24 Td (Page ${p + 1} of $totalPages) Tj ET');

      double y = pHeight - topMargin - 12.0;

      // Draw Map Image on Page 1 if present
      if (p == 0 && hasImage) {
        final double targetW = pWidth - (margin * 2);
        final double aspect = mapImageHeight / mapImageWidth;
        final double targetH = (targetW * aspect).clamp(180.0, pHeight * 0.45);
        final double imgX = margin;
        final double imgY = y - targetH;

        // Draw Map Image XObject (/Im1)
        streamBuffer.writeln('q ${targetW.toStringAsFixed(2)} 0 0 ${targetH.toStringAsFixed(2)} ${imgX.toStringAsFixed(2)} ${imgY.toStringAsFixed(2)} cm /Im1 Do Q');

        // Draw Thin Map Canvas Border Outline
        streamBuffer.writeln('0.5 w 0.1 0.1 0.1 RG ${imgX.toStringAsFixed(2)} ${imgY.toStringAsFixed(2)} ${targetW.toStringAsFixed(2)} ${targetH.toStringAsFixed(2)} re s');

        y = imgY - 16.0; // Position text below the map image canvas
      }

      for (var line in pagesLines[p]) {
        final sanitizedLine = _sanitizePdfText(line);

        if (sanitizedLine.startsWith('# ')) {
          final clean = sanitizedLine.substring(2).trim();
          streamBuffer.writeln('BT /F2 16 Tf $margin $y Td (${_escapePdf(clean)}) Tj ET');
          y -= 22.0;
        } else if (sanitizedLine.startsWith('## ')) {
          final clean = sanitizedLine.substring(3).trim();
          streamBuffer.writeln('BT /F2 13 Tf $margin $y Td (${_escapePdf(clean)}) Tj ET');
          y -= 18.0;
        } else if (sanitizedLine.startsWith('### ')) {
          final clean = sanitizedLine.substring(4).trim();
          streamBuffer.writeln('BT /F2 10 Tf $margin $y Td (${_escapePdf(clean)}) Tj ET');
          y -= 15.0;
        } else if (sanitizedLine.startsWith('> ')) {
          final clean = sanitizedLine.substring(2).trim();
          streamBuffer.writeln('BT /F2 9 Tf ${margin + 10} $y Td (${_escapePdf(clean)}) Tj ET');
          y -= 13.0;
        } else if (sanitizedLine.trim().isEmpty) {
          y -= 8.0;
        } else {
          // Check for Hex color entries in Legend lines to draw visual color boxes/lines
          if (sanitizedLine.contains('Hex #')) {
            final hexMatch = RegExp(r'Hex #([0-9A-Fa-f]{6})').firstMatch(sanitizedLine);
            if (hexMatch != null) {
              final hexCode = hexMatch.group(1)!;
              final rgb = _parseHexToRgb(hexCode);

              if (rgb != null) {
                if (sanitizedLine.toLowerCase().contains('order') || sanitizedLine.toLowerCase().contains('stream')) {
                  // Draw Vector Line Legend Symbol
                  streamBuffer.writeln('${rgb.$1.toStringAsFixed(3)} ${rgb.$2.toStringAsFixed(3)} ${rgb.$3.toStringAsFixed(3)} RG 2.0 w ${margin} ${y + 3} m ${margin + 16} ${y + 3} l S 0 0 0 RG');
                } else {
                  // Draw Filled Vector Color Box Legend Symbol
                  streamBuffer.writeln('${rgb.$1.toStringAsFixed(3)} ${rgb.$2.toStringAsFixed(3)} ${rgb.$3.toStringAsFixed(3)} rg ${margin} ${y} 12 9 re f 0 0 0 RG 0.5 w ${margin} ${y} 12 9 re s');
                }
              }
            }
            final cleanText = sanitizedLine.replaceAll(RegExp(r'Hex #[0-9A-Fa-f]{6}'), '').trim();
            streamBuffer.writeln('BT /F1 9 Tf ${margin + 20} $y Td (${_escapePdf(cleanText.replaceAll('- **', '').replaceAll('**: ', ': '))}) Tj ET');
          } else {
            streamBuffer.writeln('BT /F1 9 Tf $margin $y Td (${_escapePdf(sanitizedLine.trim())}) Tj ET');
          }
          y -= 12.0;
        }
      }

      final streamBytes = convert.utf8.encode(streamBuffer.toString());
      writeObject(streamObjId, '<< /Length ${streamBytes.length} >>\nstream\n${streamBuffer.toString()}endstream');
    }

    // Cross-Reference Table (xref)
    final startXref = pdfBytes.length;
    final totalObjects = currentObjId;

    writeString('xref\n0 $totalObjects\n0000000000 65535 f \n');
    for (int i = 1; i < totalObjects; i++) {
      final offsetStr = offsets[i].toString().padLeft(10, '0');
      writeString('$offsetStr 00000 n \n');
    }

    // Trailer
    writeString('trailer\n<< /Size $totalObjects /Root 1 0 R >>\nstartxref\n$startXref\n%%EOF\n');

    return pdfBytes;
  }

  (double, double, double)? _parseHexToRgb(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final r = int.parse(clean.substring(0, 2), radix: 16) / 255.0;
      final g = int.parse(clean.substring(2, 4), radix: 16) / 255.0;
      final b = int.parse(clean.substring(4, 6), radix: 16) / 255.0;
      return (r, g, b);
    }
    return null;
  }

  String _sanitizePdfText(String text) {
    return text
        .replaceAll('°', ' deg')
        .replaceAll('²', '^2')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('’', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"');
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
    List<int>? mapRgbBytes,
    int? mapImageWidth,
    int? mapImageHeight,
  }) {
    try {
      final pdfBytes = compileMarkdownToPdf(
        documentTitle: documentTitle,
        subtitle: subtitle,
        markdownContent: markdownContent,
        customWidth: customWidth,
        customHeight: customHeight,
        mapRgbBytes: mapRgbBytes,
        mapImageWidth: mapImageWidth,
        mapImageHeight: mapImageHeight,
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
