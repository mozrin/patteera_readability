import 'package:flutter/services.dart';
import 'package:patteera_reader/services/config_service.dart';

class ReadabilityService {
  final ConfigService _configService;

  // Maps band name to set of words
  Map<String, Set<String>> _wordLists = {};
  bool _isLoaded = false;

  ReadabilityService(this._configService);

  /// Loads the word lists defined in the config if not already loaded.
  Future<void> _loadWordLists() async {
    if (_isLoaded) return;

    final config = _configService.get('algorithm');
    if (config == null || config['bands'] == null) return;

    final bands = config['bands'] as List;

    for (var band in bands) {
      final String name = band['name'];
      final String path = band['path'];

      try {
        final content = await rootBundle.loadString(path);
        // Split by lines and whitespace to get words, lowercase them
        final words = content
            .split(RegExp(r'\s+'))
            .map((w) => w.trim().toLowerCase())
            .where((w) => w.isNotEmpty)
            .toSet();

        _wordLists[name] = words;
      } catch (e) {
        print("Error loading word list $path: $e");
        _wordLists[name] = {};
      }
    }
    _isLoaded = true;
  }

  Future<Map<String, dynamic>> analyze(String text) async {
    await _loadWordLists();

    if (text.isEmpty) {
      return {
        'score': 0.0,
        'label': 'No Text',
        'details': {'totalWords': 0},
      };
    }

    // 1. Tokenize and clean
    // Remove punctuation but keep internal hyphens or apostrophes if needed?
    // For simplicity, we'll remove all non-word chars except spaces
    final cleanText = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final tokens = cleanText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final totalWords = tokens.length;

    if (totalWords == 0) {
      return {
        'score': 0.0,
        'label': 'Insufficient Text',
        'details': {'totalWords': 0},
      };
    }

    // 2. Calculate LFP
    final config = _configService.get('algorithm');
    final bands = config['bands'] as List;

    double totalScore = 0.0;
    Map<String, int> bandCounts = {};
    Map<String, double> bandPercentages = {};

    // Helper to check which band a word belongs to (prioritizing 1st band, then 2nd...)
    // Actually, usually we check if it is in K1, if not check K2, etc.
    // The bands in config should be ordered by priority (e.g. 1k, 2k, 3k).

    int identifiedWords = 0;

    for (var word in tokens) {
      bool found = false;
      for (var band in bands) {
        final String name = band['name'];
        final Set<String> list = _wordLists[name] ?? {};

        if (list.contains(word)) {
          bandCounts[name] = (bandCounts[name] ?? 0) + 1;
          found = true;
          break; // Stop checking other bands for this word
        }
      }
      if (found) identifiedWords++;
    }

    // Calculate Percentages and Weighted Score
    for (var band in bands) {
      final String name = band['name'];
      final int count = bandCounts[name] ?? 0;
      final double percent = (count / totalWords) * 100.0;
      final double weight = (band['weight'] as num).toDouble();

      bandPercentages[name] = percent;
      totalScore += percent * weight;
    }

    // Off-list words
    final offListCount = totalWords - identifiedWords;
    final offListPercent = (offListCount / totalWords) * 100.0;
    bandPercentages['Off-List'] = offListPercent;

    // 3. Determine Label
    String label = _getLabel(totalScore);

    // Format details for UI
    Map<String, dynamic> details = {
      'totalWords': totalWords,
      'score': totalScore, // This is the coverage score
      'offList': offListPercent,
      ...bandPercentages,
    };

    return {'score': totalScore, 'label': label, 'details': details};
  }

  String _getLabel(double score) {
    final config = _configService.get('algorithm');
    if (config != null &&
        config['classification'] != null &&
        config['classification']['thresholds'] != null) {
      final thresholds = config['classification']['thresholds'] as List;
      for (var t in thresholds) {
        if (score >= (t['score'] as num).toDouble()) {
          return t['label'];
        }
      }
    }
    return "Unknown";
  }
}
