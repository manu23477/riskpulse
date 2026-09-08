import 'package:flutter/material.dart';
import 'package:riskpulse/domain/osint/promotion_candidate.dart';
import 'package:riskpulse/domain/osint/human_review_decision.dart';
import 'package:riskpulse/domain/osint/promotion_result.dart';
import 'package:riskpulse/data/services/osint/controlled_promotion_gate.dart';

/// Modal dialog for human review evaluation and controlled operational promotion.
class HumanReviewDialog extends StatefulWidget {
  final PromotionCandidate candidate;
  final ControlledPromotionGate promotionGate;
  final void Function(PromotionResult result)? onPromotionComplete;

  const HumanReviewDialog({
    super.key,
    required this.candidate,
    required this.promotionGate,
    this.onPromotionComplete,
  });

  @override
  State<HumanReviewDialog> createState() => _HumanReviewDialogState();
}

class _HumanReviewDialogState extends State<HumanReviewDialog> {
  final _reviewerController = TextEditingController(
    text: 'reviewer-analyst-01',
  );
  final _rationaleController = TextEditingController();
  ReviewDecisionType _selectedDecision = ReviewDecisionType.approved;
  bool _acknowledgedConflicts = false;

  @override
  void dispose() {
    _reviewerController.dispose();
    _rationaleController.dispose();
    super.dispose();
  }

  void _submitReview() {
    final candidate = widget.candidate;
    final gate = widget.promotionGate;

    final reviewerId = _reviewerController.text.trim();
    final rationale = _rationaleController.text.trim();

    if (reviewerId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reviewer ID is required.')));
      return;
    }

    if (_selectedDecision == ReviewDecisionType.approved && rationale.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Approval requires a non-empty review rationale.'),
        ),
      );
      return;
    }

    final review = HumanReviewDecision(
      reviewId: 'rev-${DateTime.now().millisecondsSinceEpoch}',
      promotionCandidateId: candidate.candidateId,
      reviewerId: reviewerId,
      reviewerRole: 'seniorDisasterAnalyst',
      decision: _selectedDecision,
      reviewedAt: DateTime.now().toUtc(),
      rationale: rationale,
      acknowledgedConflicts: _acknowledgedConflicts,
    );

    final result = gate.promoteCandidate(candidate: candidate, review: review);

    if (widget.onPromotionComplete != null) {
      widget.onPromotionComplete!(result);
    }

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.candidate;

    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          const Icon(Icons.gavel_outlined, color: Colors.tealAccent, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Human Review Gate: ${c.title}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Candidate ID: ${c.candidateId}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Event Type: ${c.eventType.name.toUpperCase()}',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Spatial Precision: ${c.spatialRef.spatialPrecision.name} (${c.spatialRef.placeName ?? "Coordinates"})',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              'Fusion Confidence: ${(c.fusionConfidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            if (c.hasCrossStreamConflict) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.redAccent, width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'WARNING: Unresolved cross-stream conflict exists.',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(color: Color(0xFF334155), height: 20),
            const Text(
              'Reviewer Decision',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            RadioListTile<ReviewDecisionType>(
              title: const Text(
                'Approve for Operational Promotion',
                style: TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
              value: ReviewDecisionType.approved,
              groupValue: _selectedDecision,
              onChanged: (v) => setState(() => _selectedDecision = v!),
              activeColor: Colors.greenAccent,
            ),
            RadioListTile<ReviewDecisionType>(
              title: const Text(
                'Reject Candidate (Research Only)',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
              value: ReviewDecisionType.rejected,
              groupValue: _selectedDecision,
              onChanged: (v) => setState(() => _selectedDecision = v!),
              activeColor: Colors.redAccent,
            ),
            RadioListTile<ReviewDecisionType>(
              title: const Text(
                'Return for Further Research',
                style: TextStyle(color: Colors.amberAccent, fontSize: 12),
              ),
              value: ReviewDecisionType.returnedForFurtherReview,
              groupValue: _selectedDecision,
              onChanged: (v) => setState(() => _selectedDecision = v!),
              activeColor: Colors.amberAccent,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewerController,
              decoration: const InputDecoration(
                labelText: 'Reviewer ID',
                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                filled: true,
                fillColor: Color(0xFF1E293B),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _rationaleController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Review Rationale (Mandatory for Approval)',
                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                filled: true,
                fillColor: Color(0xFF1E293B),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            if (c.hasCrossStreamConflict) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text(
                  'I acknowledge unresolved cross-stream conflict and verify promotion validity.',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
                value: _acknowledgedConflicts,
                onChanged: (v) =>
                    setState(() => _acknowledgedConflicts = v ?? false),
                activeColor: Colors.tealAccent,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: _submitReview,
          child: const Text(
            'Execute Review Decision',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
