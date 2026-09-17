import 'package:flutter/material.dart';
import 'package:riskpulse/domain/subscription/subscription.dart';
import 'package:riskpulse/data/services/subscription/subscription_services.dart';

/// Admin Area entry point reserved exclusively for [UserRole.owner].
///
/// SCIENTIFIC & ADMINISTRATIVE GOVERNANCE:
/// Displays system dashboard, subscriber metrics, and verification reviews.
/// Owner privileges are administrative privileges and do NOT bypass scientific governance or data safety rules.
class OwnerAdminScreen extends StatefulWidget {
  final UserProfileEntity ownerUser;

  const OwnerAdminScreen({
    super.key,
    required this.ownerUser,
  });

  @override
  State<OwnerAdminScreen> createState() => _OwnerAdminScreenState();
}

class _OwnerAdminScreenState extends State<OwnerAdminScreen> {
  final OwnerAdminService _adminService = const OwnerAdminService();
  late Map<String, dynamic> _stats;

  @override
  void initState() {
    super.initState();
    _stats = _adminService.getOwnerSystemDashboardStats(widget.ownerUser);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ownerUser.role != UserRole.owner) {
      return Scaffold(
        backgroundColor: const Color(0xFF020617),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.security, color: Colors.red, size: 48.0),
              SizedBox(height: 12.0),
              Text('Access Denied', style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold)),
              SizedBox(height: 4.0),
              Text('Owner Admin privileges required.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.0)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('RiskPulse Owner & Admin Area'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'System & Commercial Administration',
                  style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: const Color(0xFF38BDF8)),
                  ),
                  child: const Text(
                    'ROLE: OWNER',
                    style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Stat Cards Grid
            Row(
              children: [
                Expanded(child: _statCard('Total Users', _stats['totalUsers'].toString(), const Color(0xFF38BDF8))),
                const SizedBox(width: 12.0),
                Expanded(child: _statCard('Citizens', _stats['citizenUsers'].toString(), Colors.white)),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(child: _statCard('Students (₹399)', _stats['studentSubscribers'].toString(), const Color(0xFF0EA5E9))),
                const SizedBox(width: 12.0),
                Expanded(child: _statCard('Researchers (₹1.5k)', _stats['researcherSubscribers'].toString(), const Color(0xFF22C55E))),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(child: _statCard('Institutions', _stats['institutionalClients'].toString(), const Color(0xFFA855F7))),
                const SizedBox(width: 12.0),
                Expanded(child: _statCard('Annual Revenue', '₹${_stats['annualRevenueInr']}', const Color(0xFFEAB308))),
              ],
            ),
            const SizedBox(height: 20.0),

            // System Health & Audit
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Health & Security Audit',
                    style: TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text('Status: ${_stats['systemHealth']}', style: const TextStyle(color: Color(0xFF22C55E), fontSize: 12.0)),
                  Text('Last Audit: ${_stats['lastAuditTimestamp']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.0)),
          const SizedBox(height: 4.0),
          Text(value, style: TextStyle(color: color, fontSize: 18.0, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
