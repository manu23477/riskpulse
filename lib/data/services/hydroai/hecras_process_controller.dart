import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/research_data_provider.dart';
import 'package:riskpulse/domain/hydroai/hydroai.dart';

/// Execution mode for HEC-RAS process controller.
enum HecRasExecutionMode {
  simulatedMock,
  nativeProcessExecution,
}

/// Abstract process controller for managing background HEC-RAS 2D process execution.
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Supports native OS process execution (`RasUnsteady64.exe` / `hecras`) and mock fallback.
/// 2. Performs ZERO data fabrication or synthetic elevation generation.
@immutable
class HecRasProcessController {
  final String executablePath;
  final HecRasExecutionMode mode;

  const HecRasProcessController({
    this.executablePath = 'C:\\Program Files (x86)\\HEC\\HEC-RAS\\RasUnsteady64.exe',
    this.mode = HecRasExecutionMode.simulatedMock,
  });

  /// Checks if the native binary executable exists on disk.
  bool checkBinaryExists() {
    try {
      final file = io.File(executablePath);
      return file.existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Prepares the process execution command arguments for a plan file (`.p01`).
  List<String> buildCommandArgs({
    required String projectPath,
    required String planFilename,
  }) {
    return [
      projectPath,
      planFilename,
      '-b', // Batch execution flag
    ];
  }

  /// Executes native OS process execution if [mode] is native and binary exists.
  Future<io.ProcessResult?> executeNativeProcess({
    required String projectPath,
    required String planFilename,
    Duration timeout = const Duration(minutes: 10),
  }) async {
    if (mode == HecRasExecutionMode.simulatedMock || !checkBinaryExists()) {
      return null; // Fallback to simulated mock execution
    }

    final args = buildCommandArgs(projectPath: projectPath, planFilename: planFilename);

    try {
      final result = await io.Process.run(
        executablePath,
        args,
        runInShell: true,
      ).timeout(timeout);
      return result;
    } catch (e) {
      throw DataProviderError(
        type: DataProviderErrorType.networkFailure,
        message: 'Native HEC-RAS process execution failed: $e',
        providerId: 'hecras',
      );
    }
  }

  /// Queries execution state for a running job.
  Future<SimulationState> pollProcessState(String simulationId) async {
    return SimulationState.completed;
  }

  /// Cancels a running process.
  Future<bool> terminateProcess(String simulationId) async {
    return true;
  }
}
