# V1.0 TEST STRATEGY

- **Dedicated Integration Suite**: `test/v1_0_risk_intelligence_integration_test.dart` (40 tests).
- **Golden Test**: Kotropi 2017 Landslide end-to-end integration test.
- **Coverage**: `RiskObjectAdapter` conversion, `RiskResearchSession` creation, `RISK_CENTRIC` vs `FREE_RESEARCH` handoff, buffer vs target geometry isolation, `ResearchAnalysisResult` feedback loop, version lineage, spatial/admin/risk state continuity, and negative boundary cases.
- **Regression**: Runs across all 42 test suites in the repository.
