import 'package:riskpulse/domain/forecasting/forecast_model_record.dart';
import 'package:riskpulse/data/services/forecasting/forecast_model.dart';

/// Thread-safe, deterministic registry for managing hazard forecasting models.
class ForecastModelRegistry {
  final Map<String, ForecastModel> _models = {};

  ForecastModelRegistry();

  /// Registers a [ForecastModel].
  ///
  /// Throws [ArgumentError] if model ID or version is empty, or if a model with
  /// the same ID and version is already registered.
  void registerModel(ForecastModel model) {
    final record = model.modelRecord;
    if (record.modelId.trim().isEmpty) {
      throw ArgumentError('Cannot register model with empty modelId.');
    }
    if (record.modelVersion.trim().isEmpty) {
      throw ArgumentError('Cannot register model with empty modelVersion.');
    }

    final key = _makeKey(record.modelId, record.modelVersion);
    if (_models.containsKey(key)) {
      throw ArgumentError(
        'Model "${record.modelId}" version "${record.modelVersion}" is already registered.',
      );
    }

    _models[key] = model;
  }

  /// Unregisters a model by ID and version.
  bool unregisterModel(String modelId, String modelVersion) {
    final key = _makeKey(modelId, modelVersion);
    return _models.remove(key) != null;
  }

  /// Retrieves a registered model by ID and version. Returns null if not found.
  ForecastModel? getModel(String modelId, String modelVersion) {
    final key = _makeKey(modelId, modelVersion);
    return _models[key];
  }

  /// Checks if a model with the specified ID and version is registered.
  bool hasModel(String modelId, String modelVersion) {
    final key = _makeKey(modelId, modelVersion);
    return _models.containsKey(key);
  }

  /// Lists all registered [ForecastModelRecord] entries, optionally filtered by [algorithmClass].
  List<ForecastModelRecord> listModels({String? algorithmClass}) {
    var list = _models.values.map((m) => m.modelRecord).toList();
    if (algorithmClass != null && algorithmClass.trim().isNotEmpty) {
      final cleanClass = algorithmClass.trim().toLowerCase();
      list = list.where((r) => r.algorithmClass.toLowerCase() == cleanClass).toList();
    }
    list.sort((a, b) {
      final idComp = a.modelId.compareTo(b.modelId);
      if (idComp != 0) return idComp;
      return a.modelVersion.compareTo(b.modelVersion);
    });
    return List.unmodifiable(list);
  }

  /// Total number of registered models.
  int get count => _models.length;

  /// Clears all registered models (primarily for test resets).
  void clear() {
    _models.clear();
  }

  static String _makeKey(String modelId, String modelVersion) {
    return '${modelId.trim()}:${modelVersion.trim()}';
  }
}
