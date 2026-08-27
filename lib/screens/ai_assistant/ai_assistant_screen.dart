import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riskpulse/domain/chat/chat_message.dart';
import '../../data/services/ai_assistant_service.dart';
import 'package:riskpulse/core/location/location_service.dart';
import '../../data/services/gis_data_service.dart';
import '../../data/services/community_report_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiAssistantService _aiService = AiAssistantService();
  final LocationService _locationService = LocationService();
  final GisDataService _gisService = GisDataService();
  final CommunityReportService _reportService = CommunityReportService();
  
  bool _isLoading = false;
  String? _currentAddress;
  int _nearbyHazardsCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _updateContext();
  }

  Future<void> _updateContext() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      final address = await _locationService.getAddressFromLatLng(pos);
      final hazards = await _gisService.getLandslideHazards();
      
      int count = 0;
      for (var h in hazards) {
        final dist = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, 
          h.location.latitude, h.location.longitude
        );
        if (dist < 10000) count++; // 10km radius
      }

      if (mounted) {
        setState(() {
          _currentAddress = address;
          _nearbyHazardsCount = count + _reportService.reports.length;
        });
      }
    } catch (_) {}
  }

  Future<String> _getSpatialContext() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      final address = await _locationService.getAddressFromLatLng(pos);
      final hazards = await _gisService.getLandslideHazards();
      
      String hazardInfo = "";
      for (var h in hazards) {
        final dist = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, 
          h.location.latitude, h.location.longitude
        );
        if (dist < 10000) {
          hazardInfo += "- ${h.name} (${(dist/1000).toStringAsFixed(1)}km away): ${h.remarks}\n";
        }
      }

      return "User is in $address. "
             "Nearby hazards within 10km: $_nearbyHazardsCount. "
             "Specific details:\n$hazardInfo"
             "Community reports count: ${_reportService.reports.length}.";
    } catch (e) {
      return "Location data unavailable.";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, role: MessageRole.user));
      _isLoading = true;
    });
    _scrollToBottom();

    final contextData = await _getSpatialContext();
    final response = await _aiService.sendMessage(text, contextData: contextData);

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(text: response, role: MessageRole.assistant));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RiskPulse AI', style: TextStyle(fontSize: 18)),
            if (_currentAddress != null)
              Row(
                children: [
                  Icon(Icons.location_on, size: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Text(
                    _currentAddress!,
                    style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$_nearbyHazardsCount hazards nearby',
                      style: TextStyle(fontSize: 8, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _aiService.resetChat();
              });
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildChatBubble(message);
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: Color(0xFF0B5D5E),
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.psychology_outlined,
            size: 80,
            color: Colors.black12,
          ),
          const SizedBox(height: 16),
          const Text(
            'How can I help you today?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask me about landslide risks or safety tips.',
            style: TextStyle(color: Colors.black38),
          ),
          const SizedBox(height: 24),
          _quickActionChip('What is the landslide risk in Shimla?'),
          _quickActionChip('Safety tips during heavy rainfall'),
          _quickActionChip('How does RiskPulse calculate risk?'),
        ],
      ),
    );
  }

  Widget _quickActionChip(String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: () => _handleSubmitted(label),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Colors.black12),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 18),
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: isUser
            ? Text(
                message.text,
                style: TextStyle(color: theme.colorScheme.onPrimary),
              )
            : MarkdownBody(
                data: message.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
                ),
              ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_a_photo_outlined, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              onPressed: () => _simulateDamageAnalysis(),
              tooltip: 'Analyze Damage AI',
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: _handleSubmitted,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Type your question...',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
              onPressed: () => _handleSubmitted(_controller.text),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateDamageAnalysis() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF0D9488).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.psychology, color: Color(0xFF0D9488), size: 40),
            ),
            const SizedBox(height: 24),
            const Text('AI Damage Assessment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            const Text(
              'Upload a photo of structural cracks or terrain changes. Our Gemini-powered AI will analyze if it represents an immediate disaster risk.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF475569), height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _handleSubmitted("Analyzing uploaded image for structural integrity... Found 3 hairline cracks and signs of soil creep. Recommendation: Monitor for 48 hours and check for water seepage.");
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capture & Analyze', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
