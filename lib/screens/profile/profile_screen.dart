import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/risk_engine.dart';
import '../../data/services/weather_service.dart';
import 'package:riskpulse/domain/risk/district_risk.dart';
import 'package:riskpulse/domain/user/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final WeatherService _weatherService = WeatherService();
  final List<String> _allDistricts = [
    'Chamoli', 'Kinnaur', 'Kullu', 'Leh', 'Mandi', 'Mangan', 'Ramban', 'Rudraprayag', 'Shimla', 'Uttarkashi'
  ];

  @override
  Widget build(BuildContext context) {
    final profileService = Provider.of<ProfileService>(context);
    final profile = profileService.profile;
    
    final rainfall = _weatherService.getDistrictRainfall();
    final districtRisks = RiskEngine.calculateAllDistrictsRisk(rainfall);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B5D5E),
        foregroundColor: Colors.white,
        title: const Text('User Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(profile.name, profile.email),
            const SizedBox(height: 32),
            _buildCategorySection(profile, profileService),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Watched Areas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showAddDistrictDialog(context, profileService),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Area'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (profile.watchedDistricts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('You are not monitoring any specific areas.', style: TextStyle(color: Colors.black38)),
                ),
              )
            else
              ...profile.watchedDistricts.map((dName) {
                final risk = districtRisks.firstWhere((r) => r.name == dName, 
                  orElse: () => DistrictRisk(
                    name: dName, rainfallMm: 0, riskScore: 0, 
                    riskLevel: RiskLevel.low, trend: 'Stable', recommendation: ''
                  )
                );
                return _buildWatchedDistrictCard(risk, profileService);
              }),
            const SizedBox(height: 40),
            _buildAppBranding(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(UserProfile profile, ProfileService service) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How do you use RiskPulse?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecting a category helps us tailor disaster intelligence for your specific needs.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => _showCategorySelectionDialog(context, service),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined, size: 20, color: Color(0xFF0B5D5E)),
                  const SizedBox(width: 12),
                  Text(
                    profile.categoryLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: Colors.black45),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategorySelectionDialog(BuildContext context, ProfileService service) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Your Category'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: UserCategory.values.map((cat) {
                final isSelected = service.profile.category == cat;
                return ListTile(
                  title: Text(_getCategoryLabel(cat)),
                  trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF0B5D5E)) : null,
                  onTap: () {
                    service.updateCategory(cat);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ],
        );
      },
    );
  }

  String _getCategoryLabel(UserCategory cat) {
    switch (cat) {
      case UserCategory.generalPublic: return 'General Public';
      case UserCategory.student: return 'Student';
      case UserCategory.teacherEducator: return 'Teacher / Educator';
      case UserCategory.researcherAcademic: return 'Researcher / Academic';
      case UserCategory.ngoNonProfit: return 'NGO / Non-profit';
      case UserCategory.governmentPublicAuthority: return 'Government / Public Authority';
      case UserCategory.professionalOrganization: return 'Professional / Organization';
      case UserCategory.universityInstitution: return 'University / Institution';
    }
  }

  Widget _buildAppBranding() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              'assets/branding/riskpulse_logo.png',
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'RiskPulse Intelligence',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: 0.5,
            ),
          ),
          const Text(
            'Version 1.0.0+1',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(String name, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFE8F4F3),
            child: Icon(Icons.person, size: 40, color: Color(0xFF0B5D5E)),
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildWatchedDistrictCard(DistrictRisk risk, ProfileService service) {
    final color = _getRiskColor(risk.riskLevel);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(risk.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text('${risk.riskLevelLabel} Risk • ${risk.rainfallMm.round()}mm rain', 
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
            onPressed: () => service.removeDistrict(risk.name),
          ),
        ],
      ),
    );
  }

  void _showAddDistrictDialog(BuildContext context, ProfileService service) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Watch an Area'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _allDistricts.length,
              itemBuilder: (context, index) {
                final d = _allDistricts[index];
                final isWatched = service.profile.watchedDistricts.contains(d);
                return ListTile(
                  title: Text(d),
                  trailing: isWatched ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: isWatched ? null : () {
                    service.addDistrict(d);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ],
        );
      },
    );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low: return Colors.green;
      case RiskLevel.moderate: return Colors.orange;
      case RiskLevel.high: return Colors.red;
      case RiskLevel.extreme: return Colors.purple;
    }
  }
}
