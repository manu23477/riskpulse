import 'package:http/http.dart' as http;
import 'package:riskpulse/domain/osint/osint_source.dart';
import 'package:riskpulse/domain/osint/osint_evidence.dart';
import 'package:riskpulse/data/services/osint/osint_source_adapter.dart';
import 'package:riskpulse/data/services/osint/osint_normalizer.dart';
import 'package:riskpulse/data/services/osint/rss_atom_parser.dart';

/// Concrete [OSINTSourceAdapter] for public RSS 2.0 and Atom 1.0 feeds.
///
/// Converts raw public feed entries into immutable [OSINTEvidence] domain objects
/// with deterministic SHA-256 content fingerprints and provenance tracking.
class RssAtomSourceAdapter implements OSINTSourceAdapter {
  final http.Client _httpClient;

  RssAtomSourceAdapter({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  @override
  Future<List<OSINTEvidence>> fetchEvidence(
    OSINTSource source, {
    DateTime? since,
  }) async {
    if (!source.isValid) {
      throw OSINTAdapterException(
        type: OSINTAdapterErrorType.invalidSourceIdentity,
        message: 'Invalid OSINTSource identity or publisher parameters.',
        sourceId: source.sourceId,
      );
    }

    final feedUrl = source.canonicalUrl;
    if (feedUrl == null || feedUrl.trim().isEmpty) {
      throw OSINTAdapterException(
        type: OSINTAdapterErrorType.invalidSourceIdentity,
        message: 'Source canonicalUrl is required for feed retrieval.',
        sourceId: source.sourceId,
      );
    }

    late final http.Response response;
    try {
      response = await _httpClient.get(
        Uri.parse(feedUrl),
        headers: {
          'User-Agent':
              'RiskPulse-OSINT-Adapter/1.0 (Disaster Risk Intelligence)',
          'Accept':
              'application/rss+xml, application/atom+xml, text/xml, application/xml',
        },
      );
    } catch (e) {
      throw OSINTAdapterException(
        type: OSINTAdapterErrorType.networkFailure,
        message: 'Failed to retrieve feed from $feedUrl: $e',
        sourceId: source.sourceId,
      );
    }

    if (response.statusCode != 200) {
      throw OSINTAdapterException(
        type: OSINTAdapterErrorType.httpError,
        message:
            'HTTP ${response.statusCode} error retrieving feed from $feedUrl.',
        sourceId: source.sourceId,
        statusCode: response.statusCode,
      );
    }

    final rawXml = response.body;
    if (rawXml.trim().isEmpty) {
      throw OSINTAdapterException(
        type: OSINTAdapterErrorType.emptyContent,
        message: 'Feed payload returned from $feedUrl was empty.',
        sourceId: source.sourceId,
      );
    }

    final rawEntries = RssAtomParser.parse(rawXml);
    final retrievedAt = DateTime.now().toUtc();
    final List<OSINTEvidence> results = [];

    for (int i = 0; i < rawEntries.length; i++) {
      final entry = rawEntries[i];

      final rawText = entry.content ?? entry.description ?? entry.title ?? '';
      final normText = OSINTNormalizer.normalizeText(rawText);

      if (normText.isEmpty) continue; // Skip entries with zero text content

      final normTitle = entry.title != null
          ? OSINTNormalizer.normalizeText(entry.title!)
          : null;

      final normUrl = OSINTNormalizer.normalizeUrl(entry.link ?? feedUrl);

      final pubDate = OSINTNormalizer.parsePublicationTimestamp(entry.pubDate);

      // Apply since filter if provided
      if (since != null && pubDate != null && pubDate.isBefore(since)) {
        continue;
      }

      final fingerprint = OSINTNormalizer.computeContentFingerprint(
        normTitle,
        normText,
      );

      final evidenceId =
          'ev-${source.sourceId}-${fingerprint.substring(0, 12)}';

      final evidence = OSINTEvidence(
        evidenceId: evidenceId,
        sourceId: source.sourceId,
        contentFingerprint: fingerprint,
        title: normTitle,
        extractedText: normText,
        canonicalUrl: normUrl,
        publishedAt: pubDate, // Retains null if missing
        retrievedAt: retrievedAt,
      );

      if (evidence.isValid) {
        results.add(evidence);
      }
    }

    return List.unmodifiable(results);
  }
}
