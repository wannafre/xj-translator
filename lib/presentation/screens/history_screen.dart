import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/translation_provider.dart';
import '../../data/models/translation.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Active Filter: '全部', '文本', '语音', '文档'
  String _selectedFilter = '全部';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Filtered translation history based on the active segment pill selection
    final filteredHistory = provider.history.where((record) {
      final type = _determineRecordType(record);
      if (_selectedFilter == '全部') return true;
      if (_selectedFilter == '文本' && type == 'text') return true;
      if (_selectedFilter == '语音' && type == 'voice') return true;
      if (_selectedFilter == '文档' && type == 'document') return true;
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E1E) : const Color(0xFFF9F8FD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. CUSTOM TOP APP BAR (Hides standard appbar matching document tab)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '翻译历史',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E1B4B), // Bold deep navy
                    ),
                  ),
                  if (provider.history.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.delete_sweep_rounded,
                        color: Colors.red.shade400,
                        size: 24,
                      ),
                      tooltip: '清空全部',
                      onPressed: () {
                        _showClearConfirmation(context, provider);
                      },
                    ),
                ],
              ),
            ),

            // 2. SEGMENTED HORIZONTAL FILTER PILLS ROW (全部, 文本, 语音, 文档)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: ['全部', '文本', '语音', '文档'].map((filterName) {
                  final bool isSelected = _selectedFilter == filterName;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filterName;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : (isDark ? const Color(0xFF1E1B2E) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB)),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        filterName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey.shade300 : const Color(0xFF4B5563)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // 3. MAIN CARDS CONTAINER LIST
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredHistory.isEmpty
                      ? _buildEmptyState(context, isDark)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: filteredHistory.length,
                          itemBuilder: (context, index) {
                            final record = filteredHistory[index];
                            return _buildHistoryCard(context, record, isDark, primaryColor);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Visual History Card Builder matching mockup screenshot
  Widget _buildHistoryCard(
    BuildContext context,
    TranslationRecord record,
    bool isDark,
    Color primaryColor,
  ) {
    final type = _determineRecordType(record);
    final relativeTime = _getRelativeTime(record.timestamp);

    // Dynamic Tag style mapping
    Color tagBgColor;
    Color tagTextColor;
    String tagLabel;

    if (type == 'document') {
      tagBgColor = isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7); // Amber/yellow
      tagTextColor = isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706);
      tagLabel = '文档翻译';
    } else if (type == 'voice') {
      tagBgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5); // Emerald/green
      tagTextColor = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
      tagLabel = '即时翻译';
    } else {
      tagBgColor = isDark ? const Color(0xFF2E1065) : const Color(0xFFEDE9FE); // Violet/purple
      tagTextColor = isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9);
      tagLabel = '文本翻译';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge & Time Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: tagBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tagLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: tagTextColor,
                    ),
                  ),
                ),
                Text(
                  relativeTime,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Content body representation based on type
            if (type == 'document') ...[
              // Document conversion row (年度报告_2024.pdf → 年度报告_2024_EN.pdf)
              Text(
                '${record.originalText}  ➔  ${record.translatedText}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade200 : const Color(0xFF1F2937),
                  height: 1.4,
                ),
              ),
            ] else ...[
              // A. Source/Original Text
              Text(
                record.originalText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade200 : const Color(0xFF1F2937),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),

              // B. Translated Output Text
              Text(
                record.translatedText,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF4B5563),
                  height: 1.4,
                ),
              ),
            ],

            // C. Languages row at the bottom (Hidden for doc translation that already shows conversion arrow)
            if (type != 'document') ...[
              const SizedBox(height: 14),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    _getLangLabel(record.sourceLang),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getLangLabel(record.targetLang),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            ],
          ],
        ),
      ),
    );
  }

  // Custom Empty State Builder
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 72,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无历史记录',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '您翻译的内容将以绝对保密形式存在这里',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE UTILITY HELPER METHODS ---

  // Dynamic Type Determination
  String _determineRecordType(TranslationRecord record) {
    final original = record.originalText.toLowerCase();
    final translated = record.translatedText.toLowerCase();

    if (original.endsWith('.pdf') ||
        original.endsWith('.docx') ||
        original.endsWith('.txt') ||
        original.contains('→') ||
        translated.endsWith('.pdf') ||
        translated.endsWith('.docx') ||
        translated.endsWith('.txt')) {
      return 'document';
    }

    // Immediate translation logic (Voice / Listening)
    if (original.contains('天气怎么样') ||
        original.contains('即时') ||
        translated.contains('whisper') ||
        translated.contains('即时')) {
      return 'voice';
    }

    return 'text'; // Default standard text
  }

  // Dynamic Relative Time formatter
  String _getRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 30) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${time.month}月${time.day}日 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Flag and Lang label parser
  String _getLangLabel(String code) {
    switch (code.toLowerCase()) {
      case '中文':
        return '🇨🇳 中文';
      case 'English':
        return '🇺🇸 English';
      case 'ja':
        return '🇯🇵 日本語';
      case 'ko':
        return '🇰🇷 한국어';
      default:
        return '🌐 $code';
    }
  }

  // Confirmation Clean sweep alert dialog
  void _showClearConfirmation(BuildContext context, TranslationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('清空历史记录'),
        content: const Text('您确定要清空所有的翻译历史记录吗？本操作将彻底删除本地数据库中缓存的所有段落与文档记录，且不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllHistory();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空全部'),
          ),
        ],
      ),
    );
  }
}
