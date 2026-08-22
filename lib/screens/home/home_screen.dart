import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../risk_map/risk_map_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../my_risk/my_risk_screen.dart';
import '../report_hazard/report_hazard_screen.dart';
import './widgets/district_risk_feed.dart';
import '../../data/services/weather_service.dart';
import '../../data/services/risk_engine.dart';
import '../../data/models/district_risk.dart';
import '../emergency/emergency_hub_screen.dart';
import '../profile/profile_screen.dart';
import '../../data/services/profile_service.dart';
import '../../core/localization/app_localizations.dart';

class RiskPulseHome extends StatefulWidget {
  const RiskPulseHome({super.key});

  @override
  State<RiskPulseHome> createState() => _RiskPulseHomeState();
}

class _RiskPulseHomeState extends State<RiskPulseHome> {
  int _selectedIndex = 0;
  final WeatherService _weatherService = WeatherService();
  List<DistrictRisk> _districtRisks = [];

  @override
  void initState() {
    super.initState();
    _loadDistrictRisks();
  }

  void _loadDistrictRisks() {
    final rainfall = _weatherService.getDistrictRainfall();
    setState(() {
      _districtRisks = RiskEngine.calculateAllDistrictsRisk(rainfall);
    });
  }

  void _onNavigationSelected(int index) {
    if (index == 0) {
      setState(() => _selectedIndex = 0);
      return;
    }
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const RiskMapScreen()));
      return;
    }
    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AiAssistantScreen()));
      return;
    }
    if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final profileService = Provider.of<ProfileService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background "Intelligence" Glow
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0D9488).withValues(alpha: 0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(l10n, languageProvider, profileService),
                  const SizedBox(height: 28),
                  _buildLocationBar(l10n),
                  const SizedBox(height: 24),
                  _buildMainDashboard(l10n),
                  const SizedBox(height: 32),
                  DistrictRiskFeed(risks: _districtRisks),
                  const SizedBox(height: 32),
                  Text(
                    l10n.translate('what_would_you_like_to_know'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildActionGrid(context, l10n),
                  const SizedBox(height: 32),
                  _buildSafetyPrinciple(l10n),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildSOSFab(l10n),
      bottomNavigationBar: _buildBottomNav(l10n),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, LanguageProvider lang, ProfileService profile) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${profile.profile.name.split(' ')[0]}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.translate('app_title'),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        const Spacer(),
        _headerAction(Icons.translate, () => lang.toggleLanguage()),
        const SizedBox(width: 12),
        _headerAction(Icons.emergency_share, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyHubScreen()));
        }),
      ],
    );
  }

  Widget _headerAction(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF0F172A), size: 22),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildLocationBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFF0D9488), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Himachal Pradesh, India',
              style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 15),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(color: Color(0xFF0D9488), fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDashboard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle background decoration
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.security, size: 150, color: Colors.white.withValues(alpha: 0.03)),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('current_risk_status'),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.translate('moderate'),
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    _buildCircularHUD(),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _hudMetric(l10n.translate('trend'), l10n.translate('increasing'), Icons.trending_up, const Color(0xFFF59E0B)),
                    _hudMetric(l10n.translate('confidence'), '81%', Icons.verified, const Color(0xFF10B981)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularHUD() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: CircularProgressIndicator(
              value: 0.52,
              strokeWidth: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              color: const Color(0xFFF59E0B),
              strokeCap: StrokeCap.round,
            ),
          ),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('52', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              Text('PTS', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hudMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w900)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, AppLocalizations l10n) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _fancyGridCard(l10n.translate('risk_map'), Icons.map_rounded, const Color(0xFF6366F1), 
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiskMapScreen()))),
        _fancyGridCard(l10n.translate('ai_assistant'), Icons.psychology_rounded, const Color(0xFF8B5CF6), 
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AiAssistantScreen()))),
        _fancyGridCard(l10n.translate('report_hazard'), Icons.add_a_photo_rounded, const Color(0xFF0D9488), 
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportHazardScreen()))),
        _fancyGridCard(l10n.translate('my_risk'), Icons.location_searching_rounded, const Color(0xFFF59E0B), 
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyRiskScreen()))),
      ],
    );
  }

  Widget _fancyGridCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 28),
                ),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyPrinciple(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Color(0xFF0D9488), size: 20),
              const SizedBox(width: 10),
              Text(
                l10n.translate('principle_title'),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.translate('principle_body'),
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.6, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSFab(AppLocalizations l10n) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyHubScreen()));
      },
      backgroundColor: const Color(0xFFE11D48),
      elevation: 6,
      icon: const Icon(Icons.sos, color: Colors.white, size: 28),
      label: Text(
        l10n.translate('sos'),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
      ),
    );
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, -10))],
      ),
      child: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavigationSelected,
        indicatorColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          _navItem(l10n.translate('home'), Icons.home_outlined, Icons.home),
          _navItem(l10n.translate('risk_map'), Icons.map_outlined, Icons.map),
          _navItem(l10n.translate('ai_assistant'), Icons.psychology_outlined, Icons.psychology),
          _navItem('Profile', Icons.person_outline, Icons.person),
        ],
      ),
    );
  }

  NavigationDestination _navItem(String label, IconData icon, IconData activeIcon) {
    return NavigationDestination(
      icon: Icon(icon, color: const Color(0xFF64748B)),
      selectedIcon: Icon(activeIcon, color: const Color(0xFF0D9488)),
      label: label,
    );
  }
}
