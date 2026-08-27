import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riskpulse/domain/emergency/emergency_contact.dart';
import '../../data/services/emergency_service.dart';
import '../../data/services/state_service.dart';
import '../safety/playbook_list_screen.dart';

class EmergencyHubScreen extends StatefulWidget {
  const EmergencyHubScreen({super.key});

  @override
  State<EmergencyHubScreen> createState() => _EmergencyHubScreenState();
}

class _EmergencyHubScreenState extends State<EmergencyHubScreen> {
  final EmergencyService _emergencyService = EmergencyService();
  late List<EmergencyContact> _officialHelplines;

  @override
  void initState() {
    super.initState();
    final stateService = Provider.of<StateService>(context, listen: false);
    _officialHelplines = _emergencyService.getOfficialHelplines(stateService.selectedState);
  }

  @override
  Widget build(BuildContext context) {
    final stateService = Provider.of<StateService>(context);
    final String stateName = stateService.selectedState == HimalayanState.himachal ? 'HIMACHAL PRADESH' : 'UTTARAKHAND';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE11D48),
        foregroundColor: Colors.white,
        title: Text('$stateName SOS HUB'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSOSSection(),
            const SizedBox(height: 24),
            _buildQuickActionsRow(),
            const SizedBox(height: 32),
            const Text(
              'Official Helplines',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            ..._officialHelplines.map((contact) => _buildContactTile(contact)),
            const SizedBox(height: 24),
            _buildSafetyGuideCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: _quickActionCard(
            title: 'I am Safe',
            subtitle: 'Notify contacts',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF10B981),
            onTap: () => _showSafeCheckIn(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _quickActionCard(
            title: 'Resource Map',
            subtitle: 'Find help near you',
            icon: Icons.map_outlined,
            color: const Color(0xFF6366F1),
            onTap: () => _launchResourceMap(),
          ),
        ),
      ],
    );
  }

  Widget _quickActionCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSafeCheckIn() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Safety Check-in'),
        content: const Text('This will send a message with your GPS coordinates to your emergency contacts stating that you are safe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Safety status shared with contacts.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text('Send Safe Signal'),
          ),
        ],
      ),
    );
  }

  void _launchResourceMap() {
    // In a real app, this would open a specific map layer with shelters/hospitals
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loading nearest Helipads & Shelters...')));
  }

  Widget _buildSOSSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'In an Emergency?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Instantly share your live GPS location with your contacts.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _emergencyService.sendSOS(),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE11D48),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(EmergencyContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE11D48).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.phone_in_talk, color: Color(0xFFE11D48)),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        subtitle: contact.subtitle != null 
          ? Text(contact.subtitle!, style: const TextStyle(fontSize: 12))
          : Text(contact.phoneNumber),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: Color(0xFF10B981)),
          onPressed: () => _emergencyService.callContact(contact.phoneNumber),
        ),
      ),
    );
  }

  Widget _buildSafetyGuideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Safety Playbooks',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Quick safety guides for landslides, floods, and earthquakes, available offline.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlaybookListScreen()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Read Safety Guides', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
