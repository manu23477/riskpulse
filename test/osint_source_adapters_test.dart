import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:riskpulse/domain/osint/osint_source.dart';
import 'package:riskpulse/data/services/osint/osint_source_adapter.dart';
import 'package:riskpulse/data/services/osint/osint_normalizer.dart';
import 'package:riskpulse/data/services/osint/rss_atom_source_adapter.dart';

void main() {
  group('Stage 2.3 Source Adapters & Normalization Engine Tests', () {
    final testSource = OSINTSource(
      sourceId: 'src-ndtv-india',
      sourceType: OSINTSourceType.newsMedia,
      publisherName: 'NDTV India',
      canonicalUrl: 'https://ndtv.com/rss/india.xml',
      reliabilityCategory: SourceReliability.establishedMedia,
    );

    const sampleRssXml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>NDTV India News</title>
    <link>https://ndtv.com</link>
    <description>Top India News Headlines</description>
    <item>
      <title>  Major Landslide Blocks Mandi-Kullu Highway  </title>
      <description><![CDATA[<p>A heavy landslide triggered by continuous rain has <b>blocked</b> traffic on NH-21 near Mandi.</p>]]></description>
      <link>https://NDTV.COM/news/landslide-mandi-12345?utm_source=rss</link>
      <pubDate>Mon, 07 Sep 2026 08:30:00 GMT</pubDate>
    </item>
    <item>
      <title>Flash Flood Warning Issued for Kangra</title>
      <description>Authorities have issued an alert for low-lying areas near Kangra river.</description>
      <link>https://ndtv.com/news/flood-kangra-67890</link>
      <pubDate>Sun, 06 Sep 2026 14:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>''';

    const sampleAtomXml = '''<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Disaster Alert Feed</title>
  <entry>
    <title>Cloudburst Reported in Kullu</title>
    <content type="html">&lt;p&gt;Flash floods and debris flow reported in Kullu valley following cloudburst.&lt;/p&gt;</content>
    <link rel="alternate" href="https://disaster.gov.in/alerts/kullu-991" />
    <published>2026-09-07T10:15:00Z</published>
  </entry>
</feed>''';

    test('1. RSS 2.0 feed parsing extracts entries and normalizes title, text, URL, and timestamp', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), equals('https://ndtv.com/rss/india.xml'));
        return http.Response(sampleRssXml, 200);
      });

      final adapter = RssAtomSourceAdapter(httpClient: mockClient);
      final evidenceList = await adapter.fetchEvidence(testSource);

      expect(evidenceList.length, equals(2));

      final first = evidenceList.first;
      expect(first.sourceId, equals('src-ndtv-india'));
      expect(first.title, equals('Major Landslide Blocks Mandi-Kullu Highway'));
      expect(first.extractedText, equals('A heavy landslide triggered by continuous rain has blocked traffic on NH-21 near Mandi.'));
      expect(first.canonicalUrl, equals('https://ndtv.com/news/landslide-mandi-12345?utm_source=rss'));
      expect(first.publishedAt, equals(DateTime.utc(2026, 9, 7, 8, 30, 0)));
      expect(first.contentFingerprint, isNotNull);
      expect(first.contentFingerprint!.length, equals(64));
    });

    test('2. Atom 1.0 feed parsing extracts entry fields and ISO 8601 publication date', () async {
      final mockClient = MockClient((request) async {
        return http.Response(sampleAtomXml, 200);
      });

      final adapter = RssAtomSourceAdapter(httpClient: mockClient);
      final evidenceList = await adapter.fetchEvidence(testSource);

      expect(evidenceList.length, equals(1));

      final entry = evidenceList.first;
      expect(entry.title, equals('Cloudburst Reported in Kullu'));
      expect(entry.extractedText, equals('Flash floods and debris flow reported in Kullu valley following cloudburst.'));
      expect(entry.publishedAt, equals(DateTime.utc(2026, 9, 7, 10, 15, 0)));
      expect(entry.canonicalUrl, equals('https://disaster.gov.in/alerts/kullu-991'));
    });

    test('3. SHA-256 fingerprinting is deterministic and whitespace-invariant', () {
      const text1 = 'A heavy   landslide blocked traffic.\n\n';
      const text2 = 'A heavy landslide blocked traffic.';

      final fp1 = OSINTNormalizer.computeContentFingerprint('Landslide Alert', text1);
      final fp2 = OSINTNormalizer.computeContentFingerprint('Landslide Alert', text2);

      expect(fp1, equals(fp2));

      final fpDiff = OSINTNormalizer.computeContentFingerprint('Landslide Alert', 'Different content text.');
      expect(fp1, isNot(equals(fpDiff)));
    });

    test('4. Missing publication timestamp remains null without fabricated DateTime.now()', () async {
      const noPubDateXml = '''<rss version="2.0">
        <channel>
          <item>
            <title>Undated Report</title>
            <description>No pubDate tag present in this item.</description>
          </item>
        </channel>
      </rss>''';

      final mockClient = MockClient((request) async {
        return http.Response(noPubDateXml, 200);
      });

      final adapter = RssAtomSourceAdapter(httpClient: mockClient);
      final evidenceList = await adapter.fetchEvidence(testSource);

      expect(evidenceList.length, equals(1));
      expect(evidenceList.first.publishedAt, isNull); // Must remain null!
    });

    test('5. Since-filter includes entries strictly after since date and preserves undated entries', () async {
      final mockClient = MockClient((request) async {
        return http.Response(sampleRssXml, 200);
      });

      final adapter = RssAtomSourceAdapter(httpClient: mockClient);
      final sinceDate = DateTime.utc(2026, 9, 7, 0, 0, 0);

      final filteredList = await adapter.fetchEvidence(testSource, since: sinceDate);

      expect(filteredList.length, equals(1));
      expect(filteredList.first.title, contains('Mandi-Kullu Highway'));
    });

    test('6. HTTP error status throws classified OSINTAdapterException', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final adapter = RssAtomSourceAdapter(httpClient: mockClient);

      expect(
        () => adapter.fetchEvidence(testSource),
        throwsA(isA<OSINTAdapterException>().having(
          (e) => e.type,
          'type',
          equals(OSINTAdapterErrorType.httpError),
        )),
      );
    });

    test('7. Network failure throws classified OSINTAdapterException', () async {
      final mockClient = MockClient((request) async {
        throw Exception('SocketException: Failed host lookup');
      });

      final adapter = RssAtomSourceAdapter(httpClient: mockClient);

      expect(
        () => adapter.fetchEvidence(testSource),
        throwsA(isA<OSINTAdapterException>().having(
          (e) => e.type,
          'type',
          equals(OSINTAdapterErrorType.networkFailure),
        )),
      );
    });

    test('8. Conservative URL normalizer lowercases host and preserves path/query', () {
      expect(
        OSINTNormalizer.normalizeUrl('HTTP://NEWS.GOV.IN/path/item?id=123'),
        equals('http://news.gov.in/path/item?id=123'),
      );
      expect(OSINTNormalizer.normalizeUrl(null), isNull);
    });

    test('9. Pure-Dart SHA-256 implementation produces valid 64-char hex string', () {
      final hex = OSINTNormalizer.sha256Hex('hello world'.codeUnits);
      expect(hex.length, equals(64));
      expect(hex, equals('b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9'));
    });
  });
}
