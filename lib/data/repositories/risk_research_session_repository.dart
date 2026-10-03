import 'package:riskpulse/domain/evidence/research_analysis_result.dart';
import 'package:riskpulse/domain/evidence/risk_intelligence_query.dart';
import 'package:riskpulse/domain/evidence/risk_research_session.dart';

/// Contract for the RiskPulse Risk Research Session Repository.
abstract class RiskResearchSessionRepository {
  /// Stores a new immutable [RiskResearchSession].
  Future<void> saveSession(RiskResearchSession session);

  /// Retrieves a [RiskResearchSession] by ID.
  Future<RiskResearchSession?> getSessionById(String sessionId);

  /// Retrieves all sessions referencing a risk object ID.
  Future<List<RiskResearchSession>> getByRiskObjectId(String riskObjectId);

  /// Stores a new immutable [ResearchAnalysisResult].
  Future<void> saveResult(ResearchAnalysisResult result);

  /// Retrieves a [ResearchAnalysisResult] by ID.
  Future<ResearchAnalysisResult?> getResultById(String resultId);

  /// Retrieves all analysis results for a session ID.
  Future<List<ResearchAnalysisResult>> getResultsBySessionId(String sessionId);

  /// Queries sessions.
  Future<List<RiskResearchSession>> querySessions(RiskIntelligenceQuery query);

  /// Queries results.
  Future<List<ResearchAnalysisResult>> queryResults(RiskIntelligenceQuery query);
}

/// In-memory local implementation of [RiskResearchSessionRepository].
class LocalRiskResearchSessionRepository implements RiskResearchSessionRepository {
  final Map<String, RiskResearchSession> _sessionsById = {};
  final Map<String, ResearchAnalysisResult> _resultsById = {};
  final Map<String, List<String>> _riskObjectSessionIndex = {};
  final Map<String, List<String>> _sessionResultIndex = {};

  @override
  Future<void> saveSession(RiskResearchSession session) async {
    _sessionsById[session.sessionId] = session;
    if (session.riskObjectId != null) {
      _riskObjectSessionIndex.putIfAbsent(session.riskObjectId!, () => []).add(session.sessionId);
    }
  }

  @override
  Future<RiskResearchSession?> getSessionById(String sessionId) async {
    return _sessionsById[sessionId];
  }

  @override
  Future<List<RiskResearchSession>> getByRiskObjectId(String riskObjectId) async {
    final ids = _riskObjectSessionIndex[riskObjectId] ?? const [];
    return ids.map((id) => _sessionsById[id]).whereType<RiskResearchSession>().toList();
  }

  @override
  Future<void> saveResult(ResearchAnalysisResult result) async {
    _resultsById[result.resultId] = result;
    _sessionResultIndex.putIfAbsent(result.originatingSessionId, () => []).add(result.resultId);
  }

  @override
  Future<ResearchAnalysisResult?> getResultById(String resultId) async {
    return _resultsById[resultId];
  }

  @override
  Future<List<ResearchAnalysisResult>> getResultsBySessionId(String sessionId) async {
    final ids = _sessionResultIndex[sessionId] ?? const [];
    return ids.map((id) => _resultsById[id]).whereType<ResearchAnalysisResult>().toList();
  }

  @override
  Future<List<RiskResearchSession>> querySessions(RiskIntelligenceQuery q) async {
    return _sessionsById.values.where((s) {
      if (q.riskObjectId != null && s.riskObjectId != q.riskObjectId) return false;
      if (q.eventHypothesisId != null && s.eventHypothesisId != q.eventHypothesisId) return false;
      if (q.mode != null && s.mode != q.mode) return false;
      if (q.sessionStatus != null && s.sessionStatus != q.sessionStatus) return false;
      if (q.createdFrom != null && s.createdAt.isBefore(q.createdFrom!)) return false;
      if (q.createdTo != null && s.createdAt.isAfter(q.createdTo!)) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }

  @override
  Future<List<ResearchAnalysisResult>> queryResults(RiskIntelligenceQuery q) async {
    return _resultsById.values.where((r) {
      if (q.riskObjectId != null && r.riskObjectId != q.riskObjectId) return false;
      if (q.createdFrom != null && r.processedAt.isBefore(q.createdFrom!)) return false;
      if (q.createdTo != null && r.processedAt.isAfter(q.createdTo!)) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }
}
