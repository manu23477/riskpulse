import 'package:flutter/material.dart';
import 'package:riskpulse/domain/help_centre/help_topic.dart';

/// Dialog displaying full details, sections, workflow steps, and limitations for a [HelpTopic].
class HelpTopicDetailDialog extends StatelessWidget {
  final HelpTopic topic;

  const HelpTopicDetailDialog({
    super.key,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    topic.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: const Color(0xFF38BDF8)),
              ),
              child: Text(
                topic.scientificStatus,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            const Divider(color: Color(0xFF334155)),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.shortSummary,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 14.0,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Sections
                    ...topic.sections.map((sec) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sec.title,
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                sec.content,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13.0,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        )),

                    // Workflow Steps
                    if (topic.workflowSteps.isNotEmpty) ...[
                      const Text(
                        'Step-by-Step Workflow',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      ...topic.workflowSteps.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0EA5E9),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 13.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16.0),
                    ],

                    // Limitations
                    if (topic.limitations.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: const Color(0xFF475569)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Scientific & Application Limitations',
                              style: TextStyle(
                                color: Color(0xFFF97316),
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              topic.limitations,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
