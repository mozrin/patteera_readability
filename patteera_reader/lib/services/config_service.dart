import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class ConfigService {
  Map<dynamic, dynamic>? _config;

  Future<void> loadConfig() async {
    final String yamlString = await rootBundle.loadString('assets/config.yaml');
    _config = loadYaml(yamlString);
  }

  dynamic get(String key) {
    if (_config == null) return null;
    return _config![key];
  }

  double getCoefficient(String key) {
    if (_config == null) return 0.0;
    try {
      final coeffs = _config!['algorithm']['coefficients'] as Map;
      return (coeffs[key] as num).toDouble();
    } catch (e) {
      print('Error loading coefficient $key: $e');
      return 0.0;
    }
  }
}
