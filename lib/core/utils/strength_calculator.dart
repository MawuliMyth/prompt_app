class StrengthCalculator {
  static int calculate(String original, String enhanced, String category) {
    int score = 0;

    // Length improvement (max 30 points)
    if (enhanced.length > original.length * 2) {
      score += 30;
    } else if (enhanced.length > original.length * 1.5) {
      score += 20;
    } else if (enhanced.length > original.length) {
      score += 10;
    }

    // Quality keywords present (max 40 points)
    final qualityKeywords = [
      'specific', 'detailed', 'context', 'format', 'example',
      'professional', 'clear', 'structured', 'comprehensive', 'precise'
    ];
    final enhancedLower = enhanced.toLowerCase();
    int keywordCount = qualityKeywords.where((k) => enhancedLower.contains(k)).length;
    score += (keywordCount * 4).clamp(0, 40);

    // Category specific keywords (max 30 points)
    final categoryKeywords = {
      'Image Generation': ['style', 'lighting', 'composition', 'resolution', 'mood'],
      'Coding': ['function', 'input', 'output', 'language', 'implement'],
      'Writing': ['tone', 'audience', 'format', 'length', 'style'],
      'Business': ['objective', 'stakeholder', 'strategy', 'outcome', 'professional'],
      'General': ['explain', 'provide', 'include', 'ensure', 'consider'],
    };
    final keywords = categoryKeywords[category] ?? categoryKeywords['General']!;
    int catCount = keywords.where((k) => enhancedLower.contains(k)).length;
    score += (catCount * 6).clamp(0, 30);

    return score.clamp(0, 100);
  }

  static String getLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Basic';
  }
}
