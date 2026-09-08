import 'package:flutter/material.dart';
import 'package:riskpulse/domain/osint/osint_evidence.dart';
import 'package:riskpulse/domain/osint/osint_source.dart';

/// Card item displaying an OSINTEvidence record with expandable content, source identity,
/// canonical URL, and content fingerprint provenance.
class EvidenceListItem extends StatefulWidget {
  final OSINTEvidence evidence;
  final OSINTSource? source;
  final VoidCallback? onTap;

  const EvidenceListItem({
    super.key,
    required this.evidence,
    this.source,
    this.onTap,
  });

  @override
  State<EvidenceListItem> createState() => _EvidenceListItemState();
}

class _EvidenceListItemState extends State<EvidenceListItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.evidence;
    final src = widget.source;

    final pubDateStr = e.publishedAt != null
        ? e.publishedAt!.toIso8601String().substring(0, 16).replaceAll('T', ' ')
        : 'Undated';

    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF334155), width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: InkWell(
        onTap: widget.onTap ?? () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getSourceTypeColor(src?.sourceType),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      src?.sourceType.name.toUpperCase() ?? 'OSINT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.title ?? 'OSINT Evidence Item (${e.evidenceId})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: _expanded ? 3 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                e.extractedText,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                maxLines: _expanded ? 10 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Publisher: ${src?.publisherName ?? e.sourceId}',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Published: $pubDateStr UTC',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
              if (_expanded) ...[
                const Divider(color: Color(0xFF334155), height: 16),
                _buildProvenanceDetails(e),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProvenanceDetails(OSINTEvidence e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (e.canonicalUrl != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: SelectableText(
              'URL: ${e.canonicalUrl}',
              style: const TextStyle(color: Colors.blueAccent, fontSize: 10),
            ),
          ),
        if (e.contentFingerprint != null)
          SelectableText(
            'SHA-256 Fingerprint: ${e.contentFingerprint}',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        if (e.spatialRef != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Spatial Ref: ${e.spatialRef!.spatialPrecision.name} (${e.spatialRef!.placeName ?? e.spatialRef!.district ?? "Coordinates"})',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 10),
            ),
          ),
      ],
    );
  }

  Color _getSourceTypeColor(OSINTSourceType? type) {
    switch (type) {
      case OSINTSourceType.official:
        return Colors.purpleAccent;
      case OSINTSourceType.newsMedia:
        return Colors.blueAccent;
      case OSINTSourceType.scientificAcademic:
        return Colors.tealAccent;
      case OSINTSourceType.citizenEyewitness:
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }
}
