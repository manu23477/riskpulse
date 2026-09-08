import 'dart:convert';
import 'dart:typed_data';

/// Deterministic text, URL, timestamp, and SHA-256 fingerprint normalizer for OSINT.
///
/// Performs 100% pure-Dart deterministic normalization without external dependencies.
class OSINTNormalizer {
  /// Normalizes raw text for fingerprinting and evidence storage.
  ///
  /// Unescapes HTML entities, strips HTML tags, normalizes newlines to \n,
  /// collapses whitespace, and trims leading/trailing spaces.
  static String normalizeText(String raw) {
    if (raw.trim().isEmpty) return '';

    String text = raw;

    // 1. Unescape common HTML entities first so encoded tags (e.g. &lt;p&gt;) can be stripped
    text = text
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');

    // 2. Strip HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // 3. Normalize carriage returns and line breaks
    text = text.replaceAll(RegExp(r'\r\n|\r'), '\n');

    // 4. Collapse multiple consecutive spaces and tabs into a single space
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');

    // 5. Collapse 3 or more consecutive newlines into double newlines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 6. Trim leading/trailing whitespace on each line and overall string
    final lines = text.split('\n').map((line) => line.trim()).toList();
    text = lines.join('\n').trim();

    return text;
  }

  /// Conservative URL normalization.
  ///
  /// Trims whitespace, lowercases scheme and host, preserves path and query parameters.
  static String? normalizeUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;

    final trimmed = rawUrl.trim();
    try {
      final uri = Uri.parse(trimmed);
      if (!uri.hasScheme) return trimmed;

      final normalizedScheme = uri.scheme.toLowerCase();
      final normalizedHost = uri.host.toLowerCase();

      final buffer = StringBuffer('$normalizedScheme://');
      if (uri.userInfo.isNotEmpty) {
        buffer.write('${uri.userInfo}@');
      }
      buffer.write(normalizedHost);
      if (uri.hasPort && uri.port != (uri.scheme == 'https' ? 443 : 80)) {
        buffer.write(':${uri.port}');
      }
      buffer.write(uri.path);
      if (uri.hasQuery) {
        buffer.write('?${uri.query}');
      }
      if (uri.hasFragment) {
        buffer.write('#${uri.fragment}');
      }

      return buffer.toString();
    } catch (_) {
      return trimmed;
    }
  }

  /// Generates a deterministic 64-character hex SHA-256 content fingerprint
  /// from title and extracted text.
  static String computeContentFingerprint(String? title, String extractedText) {
    final normTitle = normalizeText(title ?? '');
    final normText = normalizeText(extractedText);

    final combined = '$normTitle\n$normText'.trim();
    final bytes = utf8.encode(combined);

    return sha256Hex(bytes);
  }

  /// Parses RSS RFC 822/2822 and Atom ISO 8601/RFC 3339 timestamps.
  ///
  /// Returns null for missing or unparseable timestamps. Never fabricates DateTime.now().
  static DateTime? parsePublicationTimestamp(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final trimmed = raw.trim();

    // 1. Try standard ISO-8601 / RFC 3339 (Atom default)
    try {
      return DateTime.parse(trimmed).toUtc();
    } catch (_) {}

    // 2. Try parsing RSS RFC 822 / 2822 date formats (e.g. "Mon, 07 Sep 2026 08:30:00 GMT")
    try {
      final cleaned = trimmed.replaceAll(
        RegExp(r'^(Mon|Tue|Wed|Thu|Fri|Sat|Sun),\s*'),
        '',
      );

      final parts = cleaned.split(RegExp(r'\s+'));
      if (parts.length >= 4) {
        final day = int.tryParse(parts[0]);
        final monthStr = parts[1].toLowerCase();
        final year = int.tryParse(parts[2]);
        final timeParts = parts[3].split(':');

        final month = switch (monthStr) {
          'jan' => 1,
          'feb' => 2,
          'mar' => 3,
          'apr' => 4,
          'may' => 5,
          'jun' => 6,
          'jul' => 7,
          'aug' => 8,
          'sep' => 9,
          'oct' => 10,
          'nov' => 11,
          'dec' => 12,
          _ => null,
        };

        if (day != null &&
            month != null &&
            year != null &&
            timeParts.length >= 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          final second = timeParts.length > 2
              ? (int.tryParse(timeParts[2]) ?? 0)
              : 0;

          return DateTime.utc(year, month, day, hour, minute, second);
        }
      }
    } catch (_) {}

    return null;
  }

  /// Pure-Dart SHA-256 hex calculation.
  static String sha256Hex(List<int> bytes) {
    final K = const [
      0x428a2f98,
      0x71374491,
      0xb5c0fbcf,
      0xe9b5dba5,
      0x3956c25b,
      0x59f111f1,
      0x923f82a4,
      0xab1c5ed5,
      0xd807aa98,
      0x12835b01,
      0x243185be,
      0x550c7dc3,
      0x72be5d74,
      0x80deb1fe,
      0x9bdc06a7,
      0xc19bf174,
      0xe49b69c1,
      0xefbe4786,
      0x0fc19dc6,
      0x240ca1cc,
      0x2de92c6f,
      0x4a7484aa,
      0x5cb0a9dc,
      0x76f988da,
      0x983e5152,
      0xa831c66d,
      0xb00327c8,
      0xbf597fc7,
      0xc6e00bf3,
      0xd5a79147,
      0x06ca6351,
      0x14292967,
      0x27b70a85,
      0x2e1b2138,
      0x4d2c6dfc,
      0x53380d13,
      0x650a7354,
      0x766a0abb,
      0x81c2c92e,
      0x92722c85,
      0xa2bfe8a1,
      0xa81a664b,
      0xc24b8b70,
      0xc76c51a3,
      0xd192e819,
      0xd6990624,
      0xf40e3585,
      0x106aa070,
      0x19a4c116,
      0x1e376c08,
      0x2748774c,
      0x34b0bcb5,
      0x391c0cb3,
      0x4ed8aa4a,
      0x5b9cca4f,
      0x682e6ff3,
      0x748f82ee,
      0x78a5636f,
      0x84c87814,
      0x8cc70208,
      0x90befffa,
      0xa4506ceb,
      0xbef9a3f7,
      0xc67178f2,
    ];

    final bitLen = bytes.length * 8;
    final padLen = (bytes.length % 64 < 56)
        ? (56 - bytes.length % 64)
        : (120 - bytes.length % 64);

    final padded = Uint8List(bytes.length + padLen + 8);
    padded.setRange(0, bytes.length, bytes);
    padded[bytes.length] = 0x80;

    final bd = ByteData.view(padded.buffer);
    bd.setUint64(padded.length - 8, bitLen, Endian.big);

    var h0 = 0x6a09e667;
    var h1 = 0xbb67ae85;
    var h2 = 0x3c6ef372;
    var h3 = 0xa54ff53a;
    var h4 = 0x510e527f;
    var h5 = 0x9b05688c;
    var h6 = 0x1f83d9ab;
    var h7 = 0x5be0cd19;

    final w = Int32List(64);

    for (var chunkStart = 0; chunkStart < padded.length; chunkStart += 64) {
      for (var i = 0; i < 16; i++) {
        w[i] = bd.getUint32(chunkStart + i * 4, Endian.big);
      }

      for (var i = 16; i < 64; i++) {
        final s0 =
            _rotr(w[i - 15], 7) ^
            _rotr(w[i - 15], 18) ^
            ((w[i - 15] & 0xFFFFFFFF) >> 3);
        final s1 =
            _rotr(w[i - 2], 17) ^
            _rotr(w[i - 2], 19) ^
            ((w[i - 2] & 0xFFFFFFFF) >> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xFFFFFFFF;
      }

      var a = h0;
      var b = h1;
      var c = h2;
      var d = h3;
      var e = h4;
      var f = h5;
      var g = h6;
      var h = h7;

      for (var i = 0; i < 64; i++) {
        final S1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ ((~e & 0xFFFFFFFF) & g);
        final temp1 = (h + S1 + ch + K[i] + w[i]) & 0xFFFFFFFF;
        final S0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (S0 + maj) & 0xFFFFFFFF;

        h = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xFFFFFFFF;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xFFFFFFFF;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
      h5 = (h5 + f) & 0xFFFFFFFF;
      h6 = (h6 + g) & 0xFFFFFFFF;
      h7 = (h7 + h) & 0xFFFFFFFF;
    }

    return [
      h0,
      h1,
      h2,
      h3,
      h4,
      h5,
      h6,
      h7,
    ].map((val) => val.toRadixString(16).padLeft(8, '0')).join();
  }

  static int _rotr(int x, int n) {
    final v = x & 0xFFFFFFFF;
    return (((v >> n) | (v << (32 - n))) & 0xFFFFFFFF);
  }
}
