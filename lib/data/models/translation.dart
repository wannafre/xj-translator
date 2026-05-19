class TranslationRecord {
  final String originalText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final DateTime timestamp;

  TranslationRecord({
    required this.originalText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.timestamp,
  });

  // Convert to JSON Map to save to LocalStorage (SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'translatedText': translatedText,
      'sourceLang': sourceLang,
      'targetLang': targetLang,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Parse JSON Map back into Dart object
  factory TranslationRecord.fromJson(Map<String, dynamic> json) {
    return TranslationRecord(
      originalText: json['originalText'] ?? '',
      translatedText: json['translatedText'] ?? '',
      sourceLang: json['sourceLang'] ?? '中文',
      targetLang: json['targetLang'] ?? 'English',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}
