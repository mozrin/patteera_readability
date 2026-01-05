import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yaml/yaml.dart';

class ConfigService extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _configKey = 'algorithm_config';

  late Box _box;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _box = await Hive.openBox(_boxName);

    if (_box.get(_configKey) == null) {
      // First run: Load defaults from YAML
      await resetToDefaults();
    }
    _isInitialized = true;
  }

  Future<void> resetToDefaults() async {
    final String yamlString = await rootBundle.loadString('assets/config.yaml');
    final YamlMap yamlMap = loadYaml(yamlString);

    // Convert YamlMap to a writable Dart Map
    final configMap = _convertYamlToMap(yamlMap['algorithm']);
    await _box.put(_configKey, configMap);
    notifyListeners();
  }

  // Helper to convert immutable YamlMap to mutable Map/List
  dynamic _convertYamlToMap(dynamic node) {
    if (node is YamlMap) {
      return node.map(
        (key, value) => MapEntry(key.toString(), _convertYamlToMap(value)),
      );
    } else if (node is YamlList) {
      return node.map((value) => _convertYamlToMap(value)).toList();
    } else {
      return node;
    }
  }

  // Getters
  Map<String, dynamic> get config {
    final data = _box.get(_configKey);
    if (data == null) return {};
    // Ensure we return a Map<String, dynamic>, Hive usually returns Map<dynamic, dynamic>
    return Map<String, dynamic>.from(data);
  }

  List<Map<String, dynamic>> get bands {
    final rawBands = config['bands'] as List?;
    if (rawBands == null) return [];
    return rawBands.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  List<Map<String, dynamic>> get thresholds {
    final rawThresholds = config['classification']?['thresholds'] as List?;
    if (rawThresholds == null) return [];
    return rawThresholds.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Modifiers
  Future<void> updateBand(int index, Map<String, dynamic> updatedBand) async {
    final currentConfig = Map<String, dynamic>.from(config);
    final currentBands = List<Map<String, dynamic>>.from(bands);

    if (index >= 0 && index < currentBands.length) {
      currentBands[index] = updatedBand;
      currentConfig['bands'] = currentBands;
      await _box.put(_configKey, currentConfig);
      notifyListeners();
    }
  }

  Future<void> addBand(Map<String, dynamic> newBand) async {
    final currentConfig = Map<String, dynamic>.from(config);
    final currentBands = List<Map<String, dynamic>>.from(bands);

    currentBands.add(newBand);
    currentConfig['bands'] = currentBands;
    await _box.put(_configKey, currentConfig);
    notifyListeners();
  }

  Future<void> removeBand(int index) async {
    final currentConfig = Map<String, dynamic>.from(config);
    final currentBands = List<Map<String, dynamic>>.from(bands);

    if (index >= 0 && index < currentBands.length) {
      currentBands.removeAt(index);
      currentConfig['bands'] = currentBands;
      await _box.put(_configKey, currentConfig);
      notifyListeners();
    }
  }

  Future<void> updateThreshold(
    int index,
    Map<String, dynamic> updatedItem,
  ) async {
    final currentConfig = Map<String, dynamic>.from(config);
    final currentThresholds = List<Map<String, dynamic>>.from(thresholds);

    if (index >= 0 && index < currentThresholds.length) {
      currentThresholds[index] = updatedItem;
      // Sort descending by score to ensure logic works
      currentThresholds.sort(
        (a, b) => (b['score'] as num).compareTo(a['score'] as num),
      );

      currentConfig['classification'] =
          (currentConfig['classification'] as Map<dynamic, dynamic>? ?? {})
            ..['thresholds'] = currentThresholds;

      await _box.put(_configKey, currentConfig);
      notifyListeners();
    }
  }

  Future<void> addThreshold(Map<String, dynamic> newItem) async {
    final currentConfig = Map<String, dynamic>.from(config);
    final currentThresholds = List<Map<String, dynamic>>.from(thresholds);

    currentThresholds.add(newItem);
    currentThresholds.sort(
      (a, b) => (b['score'] as num).compareTo(a['score'] as num),
    );

    currentConfig['classification'] =
        (currentConfig['classification'] as Map<dynamic, dynamic>? ?? {})
          ..['thresholds'] = currentThresholds;

    await _box.put(_configKey, currentConfig);
    notifyListeners();
  }

  Future<void> removeThreshold(int index) async {
    final currentConfig = Map<String, dynamic>.from(config);
    final currentThresholds = List<Map<String, dynamic>>.from(thresholds);

    if (index >= 0 && index < currentThresholds.length) {
      currentThresholds.removeAt(index);
      // No need to sort if removing

      currentConfig['classification'] =
          (currentConfig['classification'] as Map<dynamic, dynamic>? ?? {})
            ..['thresholds'] = currentThresholds;

      await _box.put(_configKey, currentConfig);
      notifyListeners();
    }
  }
}
