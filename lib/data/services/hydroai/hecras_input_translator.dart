import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/hydroai/hydroai.dart';
import 'package:riskpulse/data/services/dem_validation_service.dart';
import 'package:riskpulse/data/services/dem_readiness_policy_service.dart';

/// Container representing generated HEC-RAS 2D project file structures.
@immutable
class HecRasProjectFiles {
  final String projectTitle;
  final String prjContent;
  final String g01Content;
  final String u01Content;
  final String p01Content;
  final AnalyticalStep provenanceStep;

  const HecRasProjectFiles({
    required this.projectTitle,
    required this.prjContent,
    required this.g01Content,
    required this.u01Content,
    required this.p01Content,
    required this.provenanceStep,
  });
}

/// Provider-neutral input translator generating HEC-RAS 2D project file structures from neutral [SimulationConfig].
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Preserves DEM readiness governance & provenance.
/// 2. Does NOT invent missing channels, boundary conditions, or Manning n values.
class HecRasInputTranslator {
  static const String translatorVersion = '0.1.8-v1';

  const HecRasInputTranslator();

  /// Validates [SimulationConfig] before HEC-RAS input translation.
  bool validateConfig(SimulationConfig config) {
    if (config.simulationId.trim().isEmpty) return false;
    if (config.eventId.trim().isEmpty) return false;
    return true;
  }

  /// Translates [SimulationConfig] into [HecRasProjectFiles] structure.
  HecRasProjectFiles translateConfig(SimulationConfig config) {
    if (!validateConfig(config)) {
      throw ArgumentError('SimulationConfig is invalid for HEC-RAS translation.');
    }

    final domain = config.domain;
    final floodplain = domain.floodplainModel;
    final dem = floodplain.demRaster;

    // 1. Extract DEM Readiness Provenance
    final String valRule = dem.metadata['validationRuleVersion'] ?? DemValidationService.validationRuleVersion;
    final String policyVer = dem.metadata['readinessPolicyVersion'] ?? DemReadinessPolicyService.policyVersion;
    final String readinessStatus = dem.metadata['readinessStatus'] ?? 'notEstablished';

    final now = DateTime.now().toUtc();

    final step = AnalyticalStep(
      name: 'hecras_input_translation',
      operationType: 'hecras_input_translate',
      parameters: {
        'translatorVersion': translatorVersion,
        'simulationId': config.simulationId,
        'eventId': config.eventId,
        'crs': domain.crs.code,
        'validationRuleVersion': valRule,
        'readinessPolicyVersion': policyVer,
        'readinessStatus': readinessStatus,
        'footprintCoveragePercentage': dem.metadata['footprintCoveragePercentage'],
        'validCellPercentage': dem.metadata['validCellPercentage'],
        'noDataPercentage': dem.metadata['noDataPercentage'],
      },
      timestamp: now,
      inputReferences: [config.simulationId, config.eventId],
    );

    // 2. Generate HEC-RAS File Headers
    final String prj = 'Proj Title=${config.eventId}\n'
        'Current Plan=p01\n'
        'Geom File=g01\n'
        'Unsteady File=u01\n'
        'Projection=${domain.crs.code}\n';

    final String g01 = 'Geom Title=Floodplain Mesh ${floodplain.floodplainId}\n'
        '2D Flow Area=${floodplain.floodplainId}\n'
        'DEM Res=${dem.cellWidth}x${dem.cellHeight}\n';

    final String u01 = 'Unsteady Title=Rainfall Forcing ${config.eventId}\n'
        'Flow Title=Boundary Hydrographs\n'
        'Start Date=${config.startTime.toIso8601String()}\n'
        'End Date=${config.endTime.toIso8601String()}\n';

    final String p01 = 'Plan Title=HEC-RAS 2D Simulation ${config.simulationId}\n'
        'Short Identifier=P01\n'
        'Program Version=${config.solverVersion}\n';

    return HecRasProjectFiles(
      projectTitle: config.eventId,
      prjContent: prj,
      g01Content: g01,
      u01Content: u01,
      p01Content: p01,
      provenanceStep: step,
    );
  }
}
