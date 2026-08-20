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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('app_title'),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              l10n.translate('tagline'),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          _iconButton(Icons.translate, () => languageProvider.toggleLanguage()),
          _iconButton(Icons.emergency_share, () {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyHubScreen()));
          }),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyHubScreen()));
        },
        backgroundColor: const Color(0xFFE11D48),
        elevation: 4,
        highlightElevation: 8,
        icon: const Icon(Icons.sos, color: Colors.white),
        label: Text(
          l10n.translate('sos'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildLocationHeader(),
              const SizedBox(height: 24),
              _buildMainDashboard(l10n),
              const SizedBox(height: 32),
              DistrictRiskFeed(risks: _districtRisks),
              const SizedBox(height: 32),
              Text(
                l10n.translate('what_would_you_like_to_know'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              _buildActionGrid(context, l10n),
              const SizedBox(height: 32),
              _buildPrincipleCard(l10n),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(l10n),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF0F172A), size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D9488).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.location_on, color: Color(0xFF0D9488), size: 18),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Region',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
            ),
            Text(
              'Himachal Pradesh, IN',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Spacer(),
        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
      ],
    );
  }

  Widget _buildMainDashboard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
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
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.translate('moderate'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              _buildCircularScore(),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricItem(l10n.translate('trend'), l10n.translate('increasing'), Icons.trending_up, const Color(0xFFF59E0B)),
              _metricItem(l10n.translate('confidence'), '81%', Icons.verified_user, const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularScore() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            value: 0.52,
            strokeWidth: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            color: const Color(0xFFF59E0B),
            strokeCap: StrokeCap.round,
          ),
        ),
        const Column(
          children: [
            Text(
              '52',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            Text(
              '/100',
              style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context, AppLocalizations l10n) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _gridCard(
          context,
          icon: Icons.add_a_photo,
          color: const Color(0xFF0D9488),
          title: l10n.translate('report_hazard'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportHazardScreen())),
        ),
        _gridCard(
          context,
          icon: Icons.map,
          color: const Color(0xFF6366F1),
          title: l10n.translate('risk_map'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiskMapScreen())),
        ),
        _gridCard(
          context,
          icon: Icons.psychology,
          color: const Color(0xFF8B5CF6),
          title: l10n.translate('ai_assistant'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AiAssistantScreen())),
        ),
        _gridCard(
          context,
          icon: Icons.location_searching,
          color: const Color(0xFFF59E0B),
          title: l10n.translate('my_risk'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyRiskScreen())),
        ),
      ],
    );
  }

  Widget _gridCard(BuildContext context, {required IconData icon, required Color color, required String title, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrincipleCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('principle_title'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('principle_body'),
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavigationSelected,
        indicatorColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined, color: Color(0xFF64748B)),
            selectedIcon: const Icon(Icons.home, color: Color(0xFF0D9488)),
            label: l10n.translate('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined, color: Color(0xFF64748B)),
            selectedIcon: const Icon(Icons.map, color: Color(0xFF0D9488)),
            label: l10n.translate('risk_map'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.psychology_outlined, color: Color(0xFF64748B)),
            selectedIcon: const Icon(Icons.psychology, color: Color(0xFF0D9488)),
            label: l10n.translate('ai_assistant'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline, color: Color(0xFF64748B)),
            selectedIcon: const Icon(Icons.person, color: Color(0xFF0D9488)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
