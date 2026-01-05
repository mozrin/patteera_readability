import 'package:flutter/services.dart';
import 'package:patteera_reader/services/config_service.dart';

class ReadabilityService {
  final ConfigService _configService;

  final Map<String, Set<String>> _wordLists = {};

  ReadabilityService(this._configService);

  void invalidateCache() {
    _wordLists.clear();
  }

  /// Loads the word lists defined in the config if not already loaded.
  Future<void> _loadWordLists() async {
    final bands = _configService.bands;

    for (var band in bands) {
      final String name = band['name'];
      final String path = band['path'];

      // Only load if not already present
      if (_wordLists.containsKey(name) && _wordLists[name]!.isNotEmpty) {
        continue;
      }

      try {
        final content = await rootBundle.loadString(path);
        final words = content
            .split(RegExp(r'\s+'))
            .map((w) => w.trim().toLowerCase())
            .where((w) => w.isNotEmpty)
            .toSet();

        _wordLists[name] = words;
      } catch (e) {
        // If it's a user defined path that might be a local file, try File
        // Local file path handling to be added
        // debugPrint("Error loading word list $path: $e");
        _wordLists[name] = {};
      }
    }
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
    // Fetch latest bands from Hive config
    final bands = _configService.bands;

    double totalScore = 0.0;
    Map<String, int> bandCounts = {};
    Map<String, double> bandPercentages = {};

    int identifiedWords = 0;

    for (var word in tokens) {
      for (var band in bands) {
        final String name = band['name'];
        final Set<String> list = _wordLists[name] ?? {};

        if (list.contains(word)) {
          bandCounts[name] = (bandCounts[name] ?? 0) + 1;
          identifiedWords++;
          break; // Assign to first matching level (priority order in config matters)
        }
      }
    }

    double weightedSum = 0.0;
    Map<String, double> bandWeights = {};

    for (var band in bands) {
      final String name = band['name'];
      final int count = bandCounts[name] ?? 0;
      final double percentage = (count / totalWords) * 100;
      final double weight = (band['weight'] as num).toDouble();

      bandPercentages[name] = percentage;
      bandWeights[name] = weight;

      // New Formula: Weighted Average of Easiness
      // Each word contributes (Weight * 10) to the score sum.
      // Example: Weight 9 -> 90 points.
      weightedSum += count * (weight * 10.0);
    }

    // Off-list words contribute 0 points (Implicitly handled by not adding to weightedSum)
    final offListCount = totalWords - identifiedWords;
    final offListPercent = (offListCount / totalWords) * 100.0;
    bandPercentages['Off-List'] = offListPercent;

    // Final Calculation: Average Score per Word
    totalScore = weightedSum / totalWords;

    // Clamp not strictly needed if weights are 0-10, but safe to keep
    if (totalScore > 100.0) totalScore = 100.0;

    // 3. Determine Label
    // The previous implementation used thresholds from config directly.
    // LFP logic varies, typically high L1+L2% = Easy.
    // Here we use the calculated 'totalScore' which is weighted sum of percentages.

    String label = 'Unknown';
    final thresholds = _configService.thresholds;

    // Check thresholds
    for (var t in thresholds) {
      if (totalScore >= (t['score'] as num).toDouble()) {
        label = t['label'];
        break;
      }
    }

    // Format details for UI
    Map<String, dynamic> details = {
      'totalWords': totalWords,
      'score': totalScore,
      'offList': offListPercent,
      'weights': bandWeights, // Add this line
      ...bandPercentages,
    };

    return {'score': totalScore, 'label': label, 'details': details};
  }
}
