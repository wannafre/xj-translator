import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/translation.dart';

class TranslationRepository {
  // Simulate API Translator with typical dictionary lookups + mock fallback
  Future<TranslationRecord> translateText({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    // 1. Simulate network delay (similar to awaiting a real network request)
    await Future.delayed(const Duration(milliseconds: 1000));

    // 2. Mock simple local translation dictionaries for testing
    String translationResult = "";
    final String cleanText = text.trim().toLowerCase();

    // Chinese to English mock
    if (sourceLang == 'zh' && targetLang == 'en') {
      if (cleanText == '你好') {
        translationResult = 'Hello / How are you';
      } else if (cleanText == '早上好') {
        translationResult = 'Good morning';
      } else if (cleanText == '再见') {
        translationResult = 'Goodbye';
      } else if (cleanText == '我爱开发') {
        translationResult = 'I love developing software!';
      } else {
        translationResult = 'Mock Translation: [ "$text" translated to English ]';
      }
    } 
    // English to Chinese mock
    else if (sourceLang == 'en' && targetLang == 'zh') {
      if (cleanText == 'hello') {
        translationResult = '你好';
      } else if (cleanText == 'good morning') {
        translationResult = '早上好';
      } else if (cleanText.contains('love')) {
        translationResult = '我喜欢 / 我爱...';
      } else {
        translationResult = '模拟翻译：[ "$text" 翻译为 中文 ]';
      }
    } 
    // Fallback translation
    else {
      translationResult = 'Mock Translation: [ "$text" from $sourceLang to $targetLang ]';
    }

    // 3. Construct and return model
    return TranslationRecord(
      originalText: text,
      translatedText: translationResult,
      sourceLang: sourceLang,
      targetLang: targetLang,
      timestamp: DateTime.now(),
    );
  }

  // Save a new record to LocalStorage
  Future<void> saveRecordToHistory(TranslationRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final List<TranslationRecord> history = await getHistory();
    
    // Add to top of list
    history.insert(0, record);
    
    // Limit to 50 items for efficiency
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    // Encode to JSON string list
    final List<String> encodedList = history
        .map((item) => json.encode(item.toJson()))
        .toList();

    await prefs.setStringList(AppConstants.keyHistoryList, encodedList);
  }

  // Get all translation history records from LocalStorage
  Future<List<TranslationRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(AppConstants.keyHistoryList);
    
    if (jsonList == null) {
      return [];
    }

    try {
      return jsonList
          .map((item) => TranslationRecord.fromJson(json.decode(item)))
          .toList();
    } catch (e) {
      print('Error parsing history list: $e');
      return [];
    }
  }

  // Clear all history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyHistoryList);
  }
}
