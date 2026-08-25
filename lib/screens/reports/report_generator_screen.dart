import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/report_service.dart';
import '../../data/services/state_service.dart';
import 'report_viewer_screen.dart';

class ReportGeneratorScreen extends StatefulWidget {
  final String? initialQuery;
  const ReportGeneratorScreen({super.key, this.initialQuery});

  @override
  State<ReportGeneratorScreen> createState() => _ReportGeneratorScreenState();
}

class _ReportGeneratorScreenState extends State<ReportGeneratorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ReportService _reportService = ReportService();
  bool _isLoading = false;
  String _selectedAudience = 'General Public';
  String _selectedDepth = 'Standard';

  final List<String> _exampleQueries = [
    "Generate a report on landslides in Mandi during the last 10 years.",
    "Prepare a detailed report on the Thunag cloudburst of 2025.",
    "Show major cloudburst events in Himachal Pradesh.",
    "Compare landslide disasters in Himachal Pradesh and Uttarakhand.",
    "Generate an avalanche report for Lahaul-Spiti.",
    "What were the major flash floods in Uttarakhand during 2013–2025?",
    "Generate a district-wise disaster profile of Mandi.",
    "Give me a report on recent disaster events in Himachal Pradesh."
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _controller.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generateReport() async {
    if (_controller.text.trim().isEmpty) return;

    final stateService = Provider.of<StateService>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      final report = await _reportService.generateReport(
        query: _controller.text,
        audience: _selectedAudience,
        depth: _selectedDepth,
        stateFilter: stateService.stateName,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportViewerScreen(report: report),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('AI Risk Reports'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildInputArea(),
                const SizedBox(height: 24),
                _buildOptions(),
                const SizedBox(height: 32),
                const Text(
                  'Try asking RiskPulse:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                ..._exampleQueries.map((q) => _exampleChip(q)),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.analytics, color: Color(0xFF6366F1), size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Intelligence Report Generator',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Ask RiskPulse to generate professional, source-aware disaster reports using verified multi-hazard data.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _controller,
        maxLines: 4,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: const InputDecoration(
          hintText: 'What would you like to know?\ne.g. "Prepare a report on the Thunag cloudburst 2025"',
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Row(
      children: [
        Expanded(
          child: _dropdownOption(
            label: 'Target Audience',
            value: _selectedAudience,
            items: ['General Public', 'Student', 'Researcher', 'Professional'],
            onChanged: (v) => setState(() => _selectedAudience = v!),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _dropdownOption(
            label: 'Report Depth',
            value: _selectedDepth,
            items: ['Quick', 'Standard', 'Detailed'],
            onChanged: (v) => setState(() => _selectedDepth = v!),
          ),
        ),
      ],
    );
  }

  Widget _dropdownOption({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _exampleChip(String query) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _controller.text = query),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  query,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _generateReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Generate Intelligence Report', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF0F172A)),
            const SizedBox(height: 24),
            const Text(
              'Analyzing Verified Databases...',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Compiling source-aware intelligence report',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
