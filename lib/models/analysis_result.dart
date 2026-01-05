class AnalysisResult {
  final double score;
  final String label;
  final Map<String, dynamic> details;

  AnalysisResult({
    required this.score,
    required this.label,
    required this.details,
  });

  factory AnalysisResult.fromMap(Map<String, dynamic> map) {
    return AnalysisResult(
      score: map['score']?.toDouble() ?? 0.0,
      label: map['label'] ?? 'Unknown',
      details: map['details'] ?? {},
    );
  }
}
