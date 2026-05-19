class AppConstants {
  // Network Constants (Axios-like base config)
  static const String apiBaseUrl = 'https://api.interpreter.caiyunai.com/v1'; // Example translation API (Caiyun)
  static const int receiveTimeout = 15000;
  static const int connectionTimeout = 15000;

  // Local Storage Keys (LocalStorage-like keys)
  static const String keyHistoryList = 'key_translation_history_list';
  static const String keyDarkModeEnabled = 'key_dark_mode_enabled';

  // Translation configuration
  static const List<Map<String, String>> supportedLanguages = [
    {'code': '中文', 'name': '中文'},
    {'code': 'English', 'name': 'English'},
    {'code': 'ja', 'name': '日本語'},
    {'code': 'ko', 'name': '한국어'},
  ];
}
