import '../models/community_report.dart';

class CommunityReportService {
  // Singleton pattern for easy access across screens
  static final CommunityReportService _instance = CommunityReportService._internal();
  factory CommunityReportService() => _instance;
  CommunityReportService._internal();

  final List<CommunityReport> _reports = [];

  List<CommunityReport> get reports => List.unmodifiable(_reports);

  void addReport(CommunityReport report) {
    _reports.add(report);
  }

  void clearReports() {
    _reports.clear();
  }
}
