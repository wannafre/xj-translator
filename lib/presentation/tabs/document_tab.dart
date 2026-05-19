import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../logic/providers/translation_provider.dart';

class DocumentTab extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const DocumentTab({
    super.key,
    this.onBackToHome,
  });

  @override
  State<DocumentTab> createState() => _DocumentTabState();
}

class _DocumentTabState extends State<DocumentTab> {
  // Stateful recently translated documents list matching the user's screenshot
  final List<Map<String, dynamic>> _documents = [
    {
      'name': '年度报告_2024.pdf',
      'type': 'PDF',
      'status': 'completed',
      'pages': 28,
      'size': '2.4MB',
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'name': '产品使用手册.docx',
      'type': 'DOC',
      'status': 'translating',
      'progress': 0.45,
      'pages': 16,
      'size': '1.8MB',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 10)),
    },
    {
      'name': '历史归档文档_2020.pdf',
      'type': 'PDF',
      'status': 'completed',
      'pages': 120,
      'size': '15.4MB',
      'createdAt': DateTime.now().subtract(const Duration(days: 8)), // 8 days old!
    },
  ];

  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    // Start automated progress increments for mock "translating" documents
    _startTranslationProgressMock();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  // Periodic timer simulator to make translating files dynamic and interactive
  void _startTranslationProgressMock() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      bool hasActiveTranslations = false;

      setState(() {
        for (var doc in _documents) {
          if (doc['status'] == 'translating') {
            hasActiveTranslations = true;
            double currentProgress = doc['progress'] ?? 0.0;
            currentProgress += 0.15; // Increments by 15% each tick

            if (currentProgress >= 1.0) {
              doc['status'] = 'completed';
              doc['progress'] = 1.0;
            } else {
              doc['progress'] = double.parse(currentProgress.toStringAsFixed(2));
            }
          }
        }
      });

      if (!hasActiveTranslations) {
        // Keep checking in case the user uploads more documents
      }
    });
  }

  // Simulate file uploader file picking list
  void _showMockFilePicker(BuildContext context, TranslationProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final mockFiles = [
          {'name': 'Soon用户手册.docx', 'type': 'DOC', 'size': '1.1MB', 'pages': 8},
          {'name': 'Qwen大模型白皮书.pdf', 'type': 'PDF', 'size': '4.5MB', 'pages': 42},
          {'name': '出国旅行常用口语.txt', 'type': 'TXT', 'size': '0.3MB', 'pages': 4},
          {'name': '财务第三季度审计.pdf', 'type': 'PDF', 'size': '3.2MB', 'pages': 20},
        ];

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottomsheet drag bar
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '选择本地文档进行离线翻译',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              // File options
              Column(
                children: mockFiles.map((file) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _getFileColor(file['type'] as String).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        file['type'] as String,
                        style: TextStyle(
                          color: _getFileColor(file['type'] as String),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      file['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text('${file['size']} · ${file['pages']}页'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        // Add newly picked mock file to local list with status 'translating'
                        _documents.insert(0, {
                          'name': file['name'] as String,
                          'type': file['type'] as String,
                          'status': 'translating',
                          'progress': 0.0,
                          'pages': file['pages'] as int,
                          'size': file['size'] as String,
                        });
                      });
                      // Make sure timer simulator is running
                      _startTranslationProgressMock();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // Get color depending on file types
  Color _getFileColor(String type) {
    if (type == 'PDF') return const Color(0xFFEF4444); // Red
    if (type == 'DOC') return const Color(0xFF3B82F6); // Blue
    return const Color(0xFF10B981); // Green for TXT/others
  }

  // Language selectors picker dialog (synced with TranslationProvider!)
  void _showLanguageSelectDialog(
    BuildContext context,
    TranslationProvider provider, {
    required bool isSource,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isSource ? '选择源语言' : '选择目标语言'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppConstants.supportedLanguages.map((lang) {
              return ListTile(
                title: Text(lang['name']!),
                trailing: (isSource ? provider.sourceLang : provider.targetLang) == lang['code']
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  if (isSource) {
                    provider.setLanguages(lang['code']!, provider.targetLang);
                  } else {
                    provider.setLanguages(provider.sourceLang, lang['code']!);
                  }
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ==================== 📲 EXCLUSIVE POP-UP BOTTOM SHEET FOR SHARING ====================
  // "分享的话做成下拉弹出框的形式，可以关联到相关应用"
  // Beautiful rounded bottom sheet displaying WeChat, QQ, and More sharing options!
  void _showShareBottomSheet(BuildContext context, String documentName) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Allow custom rounded decorations
      barrierColor: Colors.black54, // Soft overlay
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161527) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                spreadRadius: 4,
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Sleek drag indicator
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Title "分享翻译文档"
              const Text(
                '分享翻译文档',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle listing the file name
              Text(
                '文件: $documentName',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
              const SizedBox(height: 28),

              // 3. Grid of Associated Apps (WeChat, QQ, System More)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // A. WECHAT (微信) - Green Bubble
                  _buildShareOption(
                    context,
                    label: '微信',
                    color: const Color(0xFF07C160), // WeChat green
                    icon: Icons.chat_bubble_rounded,
                    onTap: () {
                      Navigator.pop(context);
                      _showShareSuccessDialog(context, '微信 (WeChat)', documentName);
                    },
                  ),

                  // B. QQ - Blue Profile
                  _buildShareOption(
                    context,
                    label: 'QQ',
                    color: const Color(0xFF009BFA), // QQ blue
                    icon: Icons.person_rounded,
                    onTap: () {
                      Navigator.pop(context);
                      _showShareSuccessDialog(context, 'QQ', documentName);
                    },
                  ),

                  // C. MORE (更多) - Grey Dots
                  _buildShareOption(
                    context,
                    label: '更多',
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB), // Grey
                    iconColor: isDark ? Colors.white70 : Colors.grey.shade700,
                    icon: Icons.more_horiz_rounded,
                    onTap: () {
                      Navigator.pop(context);
                      _showShareSuccessDialog(context, '系统级分享', documentName);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Single share option widget with click animation feedback
  Widget _buildShareOption(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Rounded Box
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(isDark ? 0.15 : 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              // Name of the app
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Share association success mockup dialog
  void _showShareSuccessDialog(BuildContext context, String appName, String documentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.share_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text('关联 $appName 分享成功'),
          ],
        ),
        content: Text('已成功唤醒本地「$appName」应用，正将翻译后的文档：\n\n📄 $documentName\n\n打包传输分享给选定的好友。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter documents based on document retention settings (e.g. 7 days)
    final cutoff = DateTime.now().subtract(Duration(days: provider.documentRetentionDays));
    final displayedDocs = _documents.where((doc) {
      if (provider.documentRetentionDays == 0) return true;
      final createdAt = doc['createdAt'] as DateTime?;
      if (createdAt == null) return true;
      return createdAt.isAfter(cutoff);
    }).toList();

    // Language labels synced with provider source and target langs
    final String srcLangName = provider.sourceLang == 'zh'
        ? '🇨🇳 中文'
        : (provider.sourceLang == 'en' ? '🇺🇸 English' : '🌐 ' + provider.sourceLang.toUpperCase());
    final String targetLangName = provider.targetLang == 'zh'
        ? '🇨🇳 中文'
        : (provider.targetLang == 'en' ? '🇺🇸 English' : '🌐 ' + provider.targetLang.toUpperCase());

    return Container(
      color: isDark ? const Color(0xFF0F0E1E) : const Color(0xFFF9F8FD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main body scrolling content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2. LARGE MAIN UPLOAD CARD
                  GestureDetector(
                    onTap: () => _showMockFilePicker(context, provider),
                    child: Container(
                      height: 190,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Download/Import Icon rounded background
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.file_download_outlined, // download-styled down-arrow icon
                              color: primaryColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '点击上传文档',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '支持 PDF  DOCX  TXT 格式',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. LANGUAGE SELECTOR PILL CARD (🇨🇳 中文 → 🇺🇸 English)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Source lang
                          GestureDetector(
                            onTap: () => _showLanguageSelectDialog(context, provider, isSource: true),
                            child: Text(
                              srcLangName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Arrow indicator
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 14),
                          // Target lang
                          GestureDetector(
                            onTap: () => _showLanguageSelectDialog(context, provider, isSource: false),
                            child: Text(
                              targetLangName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 4. SECTION HEADER "最近翻译的文档"
                  Text(
                    '最近翻译的文档',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F0E1E),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. DOCUMENTS STATEFUL LIST ITEMS
                  Column(
                    children: displayedDocs.map((doc) {
                      final bool isCompleted = doc['status'] == 'completed';
                      final typeColor = _getFileColor(doc['type']!);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            // File type rounded visual badge
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                doc['type']!,
                                style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // File Name and Info Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc['name']!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Subtitle description showing progress or completed stats
                                  Text(
                                    isCompleted
                                        ? '已翻译 · ${doc['pages']}页 · ${doc['size']}'
                                        : '翻译中... ${(doc['progress'] * 100).toInt()}% · ${doc['pages']}页 · ${doc['size']}',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Right Action: Circular progress (translating) or Share button (completed)
                            if (!isCompleted)
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  value: doc['progress'],
                                  strokeWidth: 3.0,
                                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                ),
                              )
                            else
                              // Share Action Button calling _showShareBottomSheet!
                              GestureDetector(
                                onTap: () => _showShareBottomSheet(context, doc['name']!),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.reply_rounded, // share/reply icon matching screenshot
                                    color: primaryColor,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
