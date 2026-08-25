import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../risk_map/risk_map_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../my_risk/my_risk_screen.dart';
import '../report_hazard/report_hazard_screen.dart';
import '../route_planner/route_planner_screen.dart';
import './widgets/district_risk_feed.dart';
import '../../data/services/weather_service.dart';
import '../../data/services/risk_engine.dart';
import '../../data/models/hazard.dart';
import '../../data/models/district_risk.dart';
import '../../data/models/weather_alert.dart';
import '../../data/models/yatra_status.dart';
import '../emergency/emergency_hub_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/report_generator_screen.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/forest_fire_service.dart';
import '../../data/services/yatra_service.dart';
import '../../data/services/state_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/localization/app_localizations.dart';

class RiskPulseHome extends StatefulWidget {
  const RiskPulseHome({super.key});

  @override
  State<RiskPulseHome> createState() => _RiskPulseHomeState();
}

class _RiskPulseHomeState extends State<RiskPulseHome> {
  int _selectedIndex = 0;
  final WeatherService _weatherService = WeatherService();
  final ForestFireService _fireService = ForestFireService();
  final YatraService _yatraService = YatraService();
  final StateService _stateService = StateService();
  List<DistrictRisk> _districtRisks = [];
  List<WeatherAlert> _activeAlerts = [];
  List<Hazard> _liveFires = [];
  List<YatraStatus> _yatraStatuses = [];

  // Weather Animation States
  String _currentWeather = 'sunshine'; // rain, haze, sunshine, fog
  bool _isDaytime = true;

  @override
  void initState() {
    super.initState();
    _stateService.addListener(_onStateChanged);
    _loadData();
    _updateDiurnalStatus();
  }

  @override
  void dispose() {
    _stateService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      _loadData();
    }
  }

  void _loadData() {
    _loadDistrictRisks();
    _loadWeatherAlerts();
    _loadLiveFires();
    _loadYatraStatus();
  }

  void _loadDistrictRisks() {
    final rainfall = _weatherService.getDistrictRainfall();
    final allRisks = RiskEngine.calculateAllDistrictsRisk(rainfall);
    
    // Filter risks by districts relevant to the current state
    final stateDistricts = RiskEngine.districtCoordinates.keys
        .where((d) => _isDistrictInCurrentState(d))
        .toList();

    setState(() {
      _districtRisks = allRisks.where((r) => stateDistricts.contains(r.name)).toList();
    });
  }

  bool _isDistrictInCurrentState(String district) {
    const hpDistricts = ['Mandi', 'Kinnaur', 'Shimla', 'Kullu', 'Chamba', 'Lahaul & Spiti', 'Kangra', 'Solan', 'Sirmaur', 'Bilaspur', 'Hamirpur', 'Una'];
    const ukDistricts = ['Uttarkashi', 'Chamoli', 'Rudraprayag', 'Pithoragarh', 'Bageshwar', 'Champawat', 'Nainital', 'Almora', 'Pauri Garhwal', 'Tehri Garhwal', 'Dehradun', 'Haridwar', 'Udham Singh Nagar'];
    
    if (_stateService.selectedState == HimalayanState.himachal) {
      return hpDistricts.contains(district);
    } else {
      return ukDistricts.contains(district);
    }
  }

  void _loadWeatherAlerts() {
    final allAlerts = _weatherService.getActiveAlerts();
    setState(() {
      _activeAlerts = allAlerts.where((alert) => 
        alert.affectedDistricts.any((d) => _isDistrictInCurrentState(d))
      ).toList();
    });
  }

  void _loadLiveFires() async {
    final fires = await _fireService.fetchLiveFireIncidents();
    if (mounted) {
      setState(() {
        _liveFires = fires.where((f) => f.state == _stateService.stateName).toList();
      });
    }
  }

  void _loadYatraStatus() async {
    if (_stateService.selectedState == HimalayanState.uttarakhand) {
      final statuses = await _yatraService.getCharDhamStatus();
      if (mounted) {
        setState(() {
          _yatraStatuses = statuses;
        });
      }
    } else {
      setState(() {
        _yatraStatuses = [];
      });
    }
  }

  void _updateDiurnalStatus() {
    final hour = DateTime.now().hour;
    setState(() {
      _isDaytime = hour >= 6 && hour < 18;
      // Cycle weather for simulation purposes if no real feed
      if (_districtRisks.isNotEmpty && _districtRisks[0].rainfallMm > 50) {
        _currentWeather = 'rain';
      } else if (hour < 8 || hour > 20) {
        _currentWeather = 'fog';
      } else {
        _currentWeather = 'sunshine';
      }
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
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
                  _buildHeader(l10n, languageProvider, themeProvider, profileService),
                  const SizedBox(height: 28),
                  _buildLocationBar(l10n),
                  const SizedBox(height: 24),
                  _buildMainDashboard(l10n),
                  const SizedBox(height: 28),
                  if (_activeAlerts.isNotEmpty) ...[
                    _buildWeatherAlertsSection(),
                    const SizedBox(height: 28),
                  ],
                  if (_yatraStatuses.isNotEmpty) ...[
                    _buildYatraStatusSection(l10n),
                    const SizedBox(height: 28),
                  ],
                  if (_liveFires.isNotEmpty) ...[
                    _buildLiveFiresSection(),
                    const SizedBox(height: 28),
                  ],
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

  Widget _buildHeader(AppLocalizations l10n, LanguageProvider lang, ThemeProvider theme, ProfileService profile) {
    final stateService = Provider.of<StateService>(context);
    
    return Row(
      children: [
        const _ShineFlipLogo(),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stateService.selectedState == HimalayanState.himachal 
                  ? 'Hello Himachal' 
                  : 'Hello Uttarakhand',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            _buildStateDropdown(stateService),
          ],
        ),
        const Spacer(),
        _headerAction(theme.isDarkMode ? Icons.light_mode : Icons.dark_mode, () => theme.toggleTheme()),
        const SizedBox(width: 10),
        _headerAction(Icons.translate, () => lang.toggleLanguage()),
        const SizedBox(width: 10),
        _headerAction(Icons.emergency_share, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyHubScreen()));
        }),
      ],
    );
  }

  Widget _buildStateDropdown(StateService stateService) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<HimalayanState>(
        value: stateService.selectedState,
        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
        elevation: 16,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w900,
          fontSize: 22,
          letterSpacing: -1,
        ),
        onChanged: (HimalayanState? newValue) {
          if (newValue != null) {
            stateService.setState(newValue);
          }
        },
        items: [
          DropdownMenuItem<HimalayanState>(
            value: HimalayanState.himachal,
            child: const Text('Himachal Pradesh'),
          ),
          DropdownMenuItem<HimalayanState>(
            value: HimalayanState.uttarakhand,
            child: const Text('Uttarakhand'),
          ),
        ],
      ),
    );
  }

  Widget _headerAction(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 22),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildLocationBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.translate('current_region'),
              style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'LIVE',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w900),
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
          
          // Large Animated Background Logo
          Positioned(
            right: -30,
            bottom: -30,
            child: Opacity(
              opacity: 0.08,
              child: const _ShineFlipLogo(size: 180),
            ),
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

  Widget _buildYatraStatusSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.translate('yatra_bulletin'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('REAL-TIME', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _yatraStatuses.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final status = _yatraStatuses[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoutePlannerScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: status.statusColor.withValues(alpha: 0.2), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            status.shrineName,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          Icon(Icons.wb_cloudy_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: status.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          status.statusLabel.toUpperCase(),
                          style: TextStyle(color: status.statusColor, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        status.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), height: 1.3),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'IMD Weather Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('LIVE', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _activeAlerts.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final alert = _activeAlerts[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RiskMapScreen(highlightDistricts: alert.affectedDistricts),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: alert.color.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: alert.color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: alert.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              alert.severityLabel.toUpperCase(),
                              style: TextStyle(color: alert.color, fontSize: 9, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${alert.issuedAt.hour}:${alert.issuedAt.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        alert.title,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.description,
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLiveFiresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Live Forest Fires (FSI)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('FSI FEED', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _liveFires.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final fire = _liveFires[index];
              return Container(
                width: 260,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            fire.district ?? 'Himachal Pradesh',
                            style: TextStyle(color: Colors.orange.shade700, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            fire.name.split(':').last.trim(),
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Confidence: ${fire.intensity.round()}%',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.public, color: Theme.of(context).colorScheme.secondary, size: 20),
                      onPressed: () => _launchFireInGoogleEarth(fire),
                      tooltip: 'View in 3D',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _launchFireInGoogleEarth(Hazard fire) async {
    final String lat = fire.location.latitude.toString();
    final String lon = fire.location.longitude.toString();
    final Uri url = Uri.parse('https://earth.google.com/web/@$lat,$lon,2000a,800d,35y,0h,65t,0r');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Widget _buildActionGrid(BuildContext context, AppLocalizations l10n) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6, // Aspect ratio changed to make cards shorter
      children: [
        _fancyGridCard(l10n.translate('risk_map'), Icons.map_rounded, const Color(0xFF6366F1), 
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiskMapScreen()))),
        _fancyGridCard(l10n.translate('ai_assistant'), Icons.psychology_rounded, const Color(0xFF8B5CF6), 
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AiAssistantScreen()))),
        _fancyGridCard(l10n.translate('report_hazard'), Icons.add_a_photo_rounded, const Color(0xFF0D9488), 
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportHazardScreen()))),
        _fancyGridCard(l10n.translate('tourist_safety'), Icons.directions_car_rounded, const Color(0xFFF97316), 
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RoutePlannerScreen()))),
        _fancyGridCard(l10n.translate('risk_reports'), Icons.analytics_rounded, const Color(0xFF6366F1), 
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportGeneratorScreen()))),
        _fancyGridCard(l10n.translate('my_risk'), Icons.location_searching_rounded, const Color(0xFFF59E0B), 
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyRiskScreen()))),
      ],
    );
  }

  Widget _fancyGridCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                l10n.translate('principle_title'),
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.translate('principle_body'),
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), height: 1.6, fontWeight: FontWeight.w500),
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
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, -10))],
      ),
      child: NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavigationSelected,
        indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
      icon: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
      selectedIcon: Icon(activeIcon, color: Theme.of(context).colorScheme.primary),
      label: label,
    );
  }
}

class _ShineFlipLogo extends StatefulWidget {
  final double size;
  const _ShineFlipLogo({this.size = 50});

  @override
  State<_ShineFlipLogo> createState() => _ShineFlipLogoState();
}

class _ShineFlipLogoState extends State<_ShineFlipLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _flipAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    _shineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_flipAnimation.value),
          alignment: Alignment.center,
          child: ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [
                  _shineAnimation.value - 0.2,
                  _shineAnimation.value,
                  _shineAnimation.value + 0.2,
                ],
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.6),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ).createShader(rect);
            },
            blendMode: BlendMode.srcATop,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/riskpulse logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.shield,
                    color: Theme.of(context).colorScheme.primary,
                    size: widget.size * 0.6,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RainAnimation extends StatefulWidget {
  const _RainAnimation();
  @override
  State<_RainAnimation> createState() => _RainAnimationState();
}

class _RainAnimationState extends State<_RainAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _RainPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _RainPainter extends CustomPainter {
  final double progress;
  _RainPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.2)..strokeWidth = 1.0;
    for (int i = 0; i < 20; i++) {
      double x = (i * 40.0) % size.width;
      double y = (progress * size.height + (i * 25)) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 5, y + 15), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FogAnimation extends StatefulWidget {
  const _FogAnimation();
  @override
  State<_FogAnimation> createState() => _FogAnimationState();
}

class _FogAnimationState extends State<_FogAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-2.0 + (_controller.value * 4), 0.0),
              end: Alignment(0.0 + (_controller.value * 4), 0.0),
              colors: [
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HazeAnimation extends StatelessWidget {
  const _HazeAnimation();
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.white.withValues(alpha: 0.05));
  }
}

class _SunbeamAnimation extends StatefulWidget {
  const _SunbeamAnimation();
  @override
  State<_SunbeamAnimation> createState() => _SunbeamAnimationState();
}

class _SunbeamAnimationState extends State<_SunbeamAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.8, -0.8),
              radius: 0.5 + (_controller.value * 0.2),
              colors: [
                Colors.yellow.withValues(alpha: 0.1),
                Colors.yellow.withValues(alpha: 0.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
