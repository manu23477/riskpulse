import 'package:flutter/foundation.dart';

/// Immutable raw entry extracted from an RSS or Atom XML feed.
@immutable
class RawFeedEntry {
  final String? title;
  final String? description;
  final String? content;
  final String? link;
  final String? pubDate;
  final String? guid;
  final String? author;

  const RawFeedEntry({
    this.title,
    this.description,
    this.content,
    this.link,
    this.pubDate,
    this.guid,
    this.author,
  });
}

/// Pure-Dart XML parser for RSS 2.0 and Atom 1.0 feeds.
///
/// Converts raw XML feed string into a list of [RawFeedEntry] objects.
class RssAtomParser {
  /// Parses raw XML feed content into a list of [RawFeedEntry] entries.
  ///
  /// Automatically detects whether feed is RSS 2.0 (`<item>`) or Atom 1.0 (`<entry>`).
  static List<RawFeedEntry> parse(String xmlContent) {
    if (xmlContent.trim().isEmpty) return const [];

    final String lower = xmlContent.toLowerCase();

    if (lower.contains('<feed') || lower.contains('<entry')) {
      return _parseAtom(xmlContent);
    } else if (lower.contains('<rss') ||
        lower.contains('<item') ||
        lower.contains('<channel')) {
      return _parseRss(xmlContent);
    }

    return const [];
  }

  /// Parses RSS 2.0 `<item>` elements.
  static List<RawFeedEntry> _parseRss(String xml) {
    final entries = <RawFeedEntry>[];
    final itemRegex = RegExp(
      r'<item[\s>]([\s\S]*?)<\/item>',
      caseSensitive: false,
    );
    final matches = itemRegex.allMatches(xml);

    for (final match in matches) {
      final itemBlock = match.group(1) ?? '';

      final title = _extractTagContent(itemBlock, 'title');
      final description = _extractTagContent(itemBlock, 'description');
      final contentEncoded =
          _extractTagContent(itemBlock, 'content:encoded') ??
          _extractTagContent(itemBlock, 'content');
      final link =
          _extractTagContent(itemBlock, 'link') ??
          _extractAttributeValue(itemBlock, 'link', 'href');
      final pubDate =
          _extractTagContent(itemBlock, 'pubDate') ??
          _extractTagContent(itemBlock, 'dc:date');
      final guid = _extractTagContent(itemBlock, 'guid');
      final author =
          _extractTagContent(itemBlock, 'author') ??
          _extractTagContent(itemBlock, 'dc:creator');

      entries.add(
        RawFeedEntry(
          title: title,
          description: description,
          content: contentEncoded,
          link: link,
          pubDate: pubDate,
          guid: guid,
          author: author,
        ),
      );
    }

    return entries;
  }

  /// Parses Atom 1.0 `<entry>` elements.
  static List<RawFeedEntry> _parseAtom(String xml) {
    final entries = <RawFeedEntry>[];
    final entryRegex = RegExp(
      r'<entry[\s>]([\s\S]*?)<\/entry>',
      caseSensitive: false,
    );
    final matches = entryRegex.allMatches(xml);

    for (final match in matches) {
      final entryBlock = match.group(1) ?? '';

      final title = _extractTagContent(entryBlock, 'title');
      final summary = _extractTagContent(entryBlock, 'summary');
      final content = _extractTagContent(entryBlock, 'content');
      final link = _extractAtomLink(entryBlock);
      final published =
          _extractTagContent(entryBlock, 'published') ??
          _extractTagContent(entryBlock, 'updated');
      final id = _extractTagContent(entryBlock, 'id');
      final author = _extractTagContent(entryBlock, 'name');

      entries.add(
        RawFeedEntry(
          title: title,
          description: summary,
          content: content,
          link: link,
          pubDate: published,
          guid: id,
          author: author,
        ),
      );
    }

    return entries;
  }

  /// Extracts inner text content of an XML tag, handling attributes on opening tag & CDATA blocks.
  static String? _extractTagContent(String xmlBlock, String tagName) {
    final pattern = RegExp(
      '<${RegExp.escape(tagName)}(?:\\s+[^>]*)?>([\\s\\S]*?)<\\/${RegExp.escape(tagName)}>',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(xmlBlock);
    if (match == null) return null;

    String content = match.group(1) ?? '';

    // Unescape CDATA if present: <![CDATA[...]]>
    final cdataMatch = RegExp(
      r'<!\[CDATA\[([\s\S]*?)\]\]>',
      caseSensitive: false,
    ).firstMatch(content);
    if (cdataMatch != null) {
      content = cdataMatch.group(1) ?? '';
    }

    final trimmed = content.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Extracts an attribute value from a tag (e.g. `<link href="...">`).
  static String? _extractAttributeValue(
    String xmlBlock,
    String tagName,
    String attrName,
  ) {
    final pattern = RegExp(
      '<$tagName[^>]*?$attrName=["\']([^"\']+)["\']',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(xmlBlock);
    if (match == null) return null;

    final val = match.group(1)?.trim();
    return (val == null || val.isEmpty) ? null : val;
  }

  /// Extracts the alternate or primary link from an Atom entry block.
  static String? _extractAtomLink(String entryBlock) {
    final altLink = RegExp(
      'href=["\']([^"\']+)["\']',
      caseSensitive: false,
    ).firstMatch(entryBlock);

    if (altLink != null) {
      final url = altLink.group(1)?.trim();
      if (url != null && url.isNotEmpty) return url;
    }

    return _extractTagContent(entryBlock, 'link');
  }
}
