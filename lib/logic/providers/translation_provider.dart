import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/translation.dart';
import '../../data/repositories/translation_repository.dart';
import '../services/local_llm_service.dart';

class OfflineModel {
  final String id;
  final String name;
  final String subtitle;
  final String size;
  final String type; // 'chip', 'mic', 'globe'
  bool isDownloaded;
  bool isDownloading;
  double downloadProgress;

  OfflineModel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.size,
    required this.type,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
  });
}

class TranslationProvider extends ChangeNotifier {
  final TranslationRepository _repository = TranslationRepository();
  StreamSubscription<String>? _translationSubscription;

  // Basic Reactive State
  List<TranslationRecord> _history = [];
  bool _isLoading = false;
  String _sourceLang = '中文';
  String _targetLang = 'English';
  String _currentTranslation = '';
  String _errorMessage = '';

  // 🕵️ Incognito / Privacy Mode State
  bool _isIncognito = false;

  // 💾 Memory Optimization & Retention settings
  bool _isMemoryOptimized = true;
  int _documentRetentionDays = 7; // 7 = temporary 7 days, 0 = permanent
  bool _isOfflineMode = true;

  // 🤖 Offline LLMs State matching the screenshot UI
  String _defaultModelId = 'qwen_1.5b'; // Default model is Qwen2.5-1.5B
  final List<OfflineModel> _offlineModels = [
    OfflineModel(
      id: 'qwen_1.5b',
      name: 'Qwen2.5-1.5B',
      subtitle: '当前默认',
      size: '1.5B',
      type: 'chip',
    ),
    OfflineModel(
      id: 'llama_3b',
      name: 'Llama3.2-3B',
      subtitle: '翻译质量高 · 需 3GB 存储',
      size: '3GB',
      type: 'chip',
    ),
    OfflineModel(
      id: 'whisper_tiny',
      name: 'Whisper-Tiny 语音模型',
      subtitle: '语音识别专用 · 需 800MB 存储',
      size: '800MB',
      type: 'mic',
    ),
    OfflineModel(
      id: 'nllb_200',
      name: 'NLLB-200-Distilled',
      subtitle: '200+语言支持 · 需 1.2GB 存储',
      size: '1.2GB',
      type: 'globe',
    ),
  ];

  // Getters for UI exposure
  List<TranslationRecord> get history => _history;
  bool get isLoading => _isLoading;
  String get sourceLang => _sourceLang;
  String get targetLang => _targetLang;
  String get currentTranslation => _currentTranslation;
  String get errorMessage => _errorMessage;

  bool get isIncognito => _isIncognito;
  bool get isMemoryOptimized => _isMemoryOptimized;
  int get documentRetentionDays => _documentRetentionDays;
  bool get isOfflineMode => _isOfflineMode;

  String get defaultModelId => _defaultModelId;
  List<OfflineModel> get offlineModels => _offlineModels;

  // Get the active default model object
  OfflineModel get activeDefaultModel {
    return _offlineModels.firstWhere(
      (m) => m.id == _defaultModelId,
      orElse: () => _offlineModels.first,
    );
  }

  TranslationProvider() {
    _loadSettings();
    loadHistory();
  }

  // Load offline settings & incognito status from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Incognito mode status
    _isIncognito = prefs.getBool('is_incognito') ?? false;

    // 2. Load Memory & Retention & Offline configs
    _isOfflineMode = prefs.getBool('is_offline_mode') ?? true;
    _isMemoryOptimized = prefs.getBool('is_memory_optimized') ?? true;
    _documentRetentionDays = prefs.getInt('document_retention_days') ?? 7;

    // 3. Load Default model selection
    _defaultModelId = prefs.getString('default_model_id') ?? 'qwen_1.5b';

    // 4. Load and verify actual existence of local model files (dynamic sync)
    await verifyDownloadedModels();
  }

  /// 🕵️ 检查并校验所有已下载模型文件的物理存在性。
  /// 若发现物理文件被外部（如用户手动或系统清理）删除，则自动修正内存中的状态并保存到本地持久化。
  Future<void> verifyDownloadedModels() async {
    bool stateChanged = false;
    final localLlmService = LocalLlmService();

    for (var model in _offlineModels) {
      // 正在下载中的模型不做物理校验，避免中断状态或被误判为已完成下载
      if (localLlmService.isModelDownloading(model.id)) {
        continue;
      }

      // 物理检测该模型是否存在于本地存储中（如果是 Web 平台会通过 SharedPreferences 检测状态）
      final bool actuallyDownloaded = await localLlmService.isModelDownloaded(
        model.id,
      );

      // 如果实际存在性与内存状态不匹配，进行修正
      if (model.isDownloaded != actuallyDownloaded) {
        model.isDownloaded = actuallyDownloaded;
        stateChanged = true;

        // 如果被删除的模型正好是当前默认选中的模型，自动安全降级回默认的 'qwen_1.5b'
        if (!actuallyDownloaded && _defaultModelId == model.id) {
          _defaultModelId = 'qwen_1.5b';
        }

        debugPrint(
          '🤖 [模型校验] 检测到模型 "${model.name}" (${model.id}) 的本地文件状态不一致，实际存在：$actuallyDownloaded。已自动同步！',
        );
      }
    }

    if (stateChanged) {
      notifyListeners();

      // 将最新校验后的下载状态与默认模型同步保存到 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final List<String> downloaded = _offlineModels
          .where((m) => m.isDownloaded)
          .map((m) => m.id)
          .toList();
      await prefs.setStringList('downloaded_model_ids', downloaded);
      await prefs.setString('default_model_id', _defaultModelId);
    } else {
      // 如果没有任何变动，但我们需要初次或手动刷新 UI 绑定状态时
      notifyListeners();
    }
  }

  // Toggle Incognito (无痕) Mode
  Future<void> toggleIncognitoMode(bool value) async {
    _isIncognito = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_incognito', value);
  }

  // Toggle Offline Mode
  Future<void> toggleOfflineMode(bool value) async {
    _isOfflineMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_offline_mode', value);
  }

  // Toggle Memory Optimization
  Future<void> toggleMemoryOptimized(bool value) async {
    _isMemoryOptimized = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_memory_optimized', value);
    if (value) {
      debugPrint('Memory optimization enabled: dynamic LLM weights released.');
    }
  }

  // Set Document Retention Days (e.g. 7, or 0 = permanent)
  Future<void> setDocumentRetentionDays(int days) async {
    _documentRetentionDays = days;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('document_retention_days', days);
    await loadHistory(); // Instantly apply filtering!
  }

  // 1. Load history from Local Storage with auto-cleanup of files > 7 days
  Future<void> loadHistory() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      var loadedHistory = await _repository.getHistory();
      final prefs = await SharedPreferences.getInstance();

      // If history is empty, initialize to an empty list
      if (loadedHistory.isEmpty) {
        loadedHistory = [];
      }

      // Apply automatic cleanup if document retention is configured (e.g., 7 days)
      if (_documentRetentionDays > 0) {
        final cutoff = DateTime.now().subtract(
          Duration(days: _documentRetentionDays),
        );
        bool modified = false;

        loadedHistory.removeWhere((record) {
          final isDoc =
              record.originalText.toLowerCase().endsWith('.pdf') ||
              record.originalText.toLowerCase().endsWith('.docx') ||
              record.originalText.toLowerCase().endsWith('.txt') ||
              record.originalText.contains('→');
          if (isDoc && record.timestamp.isBefore(cutoff)) {
            modified = true;
            return true;
          }
          return false;
        });

        if (modified) {
          final List<String> encodedList = loadedHistory
              .map((item) => json.encode(item.toJson()))
              .toList();
          await prefs.setStringList(AppConstants.keyHistoryList, encodedList);
        }
      }

      _history = loadedHistory;
    } catch (e) {
      _errorMessage = "无法加载历史记录";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _lastTranslatedText = '';

  // 2. Set Languages
  void setLanguages(String source, String target) {
    _sourceLang = source;
    _targetLang = target;
    notifyListeners();
    if (_lastTranslatedText.trim().isNotEmpty) {
      translateText(_lastTranslatedText);
    }
  }

  // 3. Swap Languages
  void swapLanguages() {
    final temp = _sourceLang;
    _sourceLang = _targetLang;
    _targetLang = temp;
    notifyListeners();
    if (_lastTranslatedText.trim().isNotEmpty) {
      translateText(_lastTranslatedText);
    }
  }

  // 4. Translate text action (Integrated with local model name & incognito mode check)
  Future<void> translateText(String text) async {
    _lastTranslatedText = text;
    if (text.trim().isEmpty) {
      _errorMessage = '请输入需要翻译的文本！';
      _currentTranslation = '';
      notifyListeners();
      return;
    }

    // Cancel any active translation stream to prevent overlap
    await _translationSubscription?.cancel();

    _isLoading = true;
    _errorMessage = '';
    _currentTranslation = '';
    notifyListeners();

    try {
      final localLlmService = LocalLlmService();

      // 先进行一次全面的本地模型文件状态校验（防止用户在前台/后台手动删除了文件）
      await verifyDownloadedModels();

      // Check if the default model is downloaded (on all platforms)
      final isDownloaded = await localLlmService.isModelDownloaded(
        _defaultModelId,
      );
      if (!isDownloaded) {
        _errorMessage =
            '当前默认的大模型「${activeDefaultModel.name}」未下载，请先在「模型管理」中下载该模型后使用！';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check model compatibility / availability (e.g. Whisper is voice only, not for text translation)
      if (_defaultModelId == 'whisper_tiny') {
        _errorMessage = '大模型加载错误：Whisper-Tiny 仅支持语音识别与提取，不支持文本翻译大模型推理，当前不可用！';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final stream = localLlmService.translateStream(
        text: text,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
        modelId: _defaultModelId,
      );

      _translationSubscription = stream.listen(
        (chunk) {
          _currentTranslation = chunk;
          notifyListeners();
        },
        onError: (err) {
          _errorMessage = err.toString();
          _isLoading = false;
          notifyListeners();
        },
        onDone: () async {
          _isLoading = false;

          final modelSuffix = " \n\n[⚡ 本地离线推理：${activeDefaultModel.name}]";
          final rawTranslation = _currentTranslation;
          _currentTranslation = rawTranslation + modelSuffix;
          notifyListeners();

          // 🕵️ INCOGNITO CHECK: Only save to database and active list if incognito mode is DISABLED
          if (!_isIncognito) {
            final recordToSave = TranslationRecord(
              originalText: text,
              translatedText: "$rawTranslation (${activeDefaultModel.name} 离线)",
              sourceLang: _sourceLang,
              targetLang: _targetLang,
              timestamp: DateTime.now(),
            );
            // Save record to local storage history
            await _repository.saveRecordToHistory(recordToSave);
            // Update history list in state
            _history.insert(0, recordToSave);
            notifyListeners();
          }
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // 5. Clear all history
  Future<void> clearAllHistory() async {
    await _repository.clearHistory();
    _history.clear();
    notifyListeners();
  }

  // ==================== 🤖 OFFLINE MODEL ACTION SIMULATORS ====================

  // Set selected model as default
  Future<void> setDefaultModel(String modelId) async {
    final model = _offlineModels.firstWhere((m) => m.id == modelId);
    if (!model.isDownloaded) return; // Must be downloaded to set as default

    _defaultModelId = modelId;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_model_id', modelId);
  }

  // Real and simulated GGUF model downloader using LocalLlmService
  void downloadModel(String modelId) {
    final modelIndex = _offlineModels.indexWhere((m) => m.id == modelId);
    if (modelIndex == -1 || _offlineModels[modelIndex].isDownloaded) return;

    final model = _offlineModels[modelIndex];
    model.isDownloading = true;
    model.downloadProgress = 0.0;
    notifyListeners();

    LocalLlmService().downloadModel(
      modelId: modelId,
      onProgress: (progress) {
        model.downloadProgress = progress;
        notifyListeners();
      },
      onComplete: () async {
        model.isDownloading = false;
        model.isDownloaded = true;
        model.downloadProgress = 1.0;
        notifyListeners();

        // Save downloaded list state to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final List<String> downloaded = _offlineModels
            .where((m) => m.isDownloaded)
            .map((m) => m.id)
            .toList();
        await prefs.setStringList('downloaded_model_ids', downloaded);
      },
      onError: (errorMsg) {
        model.isDownloading = false;
        model.downloadProgress = 0.0;
        _errorMessage = errorMsg;
        notifyListeners();
      },
    );
  }

  // Delete model and remove local file (preset Qwen2.5-1.5B cannot be deleted)
  Future<void> deleteModel(String modelId) async {
    if (modelId == 'qwen_1.5b') return; // Cannot delete core model

    final modelIndex = _offlineModels.indexWhere((m) => m.id == modelId);
    if (modelIndex == -1) return;

    final model = _offlineModels[modelIndex];

    // Call LocalLlmService to delete the actual local GGUF file
    final deleted = await LocalLlmService().deleteModelFile(modelId);

    if (deleted || !LocalLlmService().isNativeSupported) {
      model.isDownloaded = false;
      model.downloadProgress = 0.0;

      // If we deleted the active default model, fallback to qwen_1.5b
      if (_defaultModelId == modelId) {
        _defaultModelId = 'qwen_1.5b';
      }
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final List<String> downloaded = _offlineModels
          .where((m) => m.isDownloaded)
          .map((m) => m.id)
          .toList();
      await prefs.setStringList('downloaded_model_ids', downloaded);
      await prefs.setString('default_model_id', _defaultModelId);
    }
  }

  @override
  void dispose() {
    _translationSubscription?.cancel();
    super.dispose();
  }
}
