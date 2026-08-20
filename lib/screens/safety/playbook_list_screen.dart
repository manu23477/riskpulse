import 'package:flutter/material.dart';
import '../../data/models/safety_playbook.dart';
import '../../data/repositories/safety_repository.dart';
import 'playbook_detail_screen.dart';

class PlaybookListScreen extends StatelessWidget {
  const PlaybookListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final playbooks = SafetyRepository().getPlaybooks(languageCode);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B5D5E),
        foregroundColor: Colors.white,
        title: const Text('Safety Playbooks'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: playbooks.length,
        itemBuilder: (context, index) {
          final playbook = playbooks[index];
          return _buildPlaybookCard(context, playbook);
        },
      ),
    );
  }

  Widget _buildPlaybookCard(BuildContext context, SafetyPlaybook playbook) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaybookDetailScreen(playbook: playbook),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4F3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(playbook.icon, color: const Color(0xFF0B5D5E), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playbook.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        playbook.description,
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
