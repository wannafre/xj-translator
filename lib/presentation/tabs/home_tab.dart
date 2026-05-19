import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../logic/providers/translation_provider.dart';
import '../components/custom_button.dart';
import '../screens/model_management_screen.dart';


class HomeTab extends StatefulWidget {
  final ValueChanged<int> onNavigateToTab;

  const HomeTab({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  // Segment index: 0 = 即时翻译, 1 = 文本翻译
  int _selectedSegmentIndex = 0;

  // Controller for text input
  final TextEditingController _textController = TextEditingController();

  // Instant Translation focused state variables
  bool _isInstantActive = false;
  bool _isSoundDetected = false;
  bool _isPaused = false;

  // Simulation state variables
  Timer? _simulationTimer;
  int _simulationPhase = 0;
  String _simulatedSpoken = "";
  String _simulatedTranslated = "";

  // Wave phase animation controller
  AnimationController? _waveController;

  // Debounce timer for text instant translation
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _waveController?.dispose();
    _simulationTimer?.cancel();
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  // Auto-translation debounce for text translator
  void _onTextChanged(String text, TranslationProvider provider) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (text.trim().isNotEmpty) {
        provider.translateText(text);
      }
    });
  }

  // Start instant translation live listening simulation loop
  void _startInstantSimulation(TranslationProvider provider) {
    _waveController?.repeat();
    _simulationTimer?.cancel();
    _simulationPhase = 0;
    _simulatedSpoken = "";
    _simulatedTranslated = "";
    _isPaused = false;
    _isSoundDetected = false;

    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isPaused) return;

      setState(() {
        _simulationPhase = (_simulationPhase + 1) % 4;

        if (_simulationPhase == 0) {
          // Phase 0: Silent Listening
          _isSoundDetected = false;
          _simulatedSpoken = "";
          _simulatedTranslated = "";
        } else if (_simulationPhase == 1) {
          // Phase 1: Sound Detected (Microphone glows green, wave oscillates actively!)
          _isSoundDetected = true;
        } else if (_simulationPhase == 2) {
          // Phase 2: Speech recognized (Spoken text appears)
          _isSoundDetected = false;
          _simulatedSpoken = provider.sourceLang == 'zh'
              ? "你好，请问这附近有没有好的餐厅推荐？"
              : "Hello, are there any good restaurants nearby that you would recommend?";
        } else if (_simulationPhase == 3) {
          // Phase 3: Translation completed (Translated text appears)
          _isSoundDetected = false;
          _simulatedTranslated = provider.sourceLang == 'zh'
              ? "Hello, are there any good restaurants nearby that you would recommend?"
              : "你好，请问这附近有没有好的餐厅推荐？";
        }
      });
    });
  }

  // Stop simulation loop
  void _stopInstantSimulation() {
    _waveController?.stop();
    _simulationTimer?.cancel();
    _simulationTimer = null;
    setState(() {
      _isInstantActive = false;
      _isSoundDetected = false;
      _simulatedSpoken = "";
      _simulatedTranslated = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // IMMERSIVE LIVE LISTENING MODE (Focused screen exactly matching user's screenshot)
    if (_selectedSegmentIndex == 0 && _isInstantActive) {
      return _buildFocusedInstantScreen(context, provider, primaryColor, isDark);
    }

    // STANDARD MODE (Regular Tab Layout)
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A. Translation Mode Segment Bar (即时翻译, 文本翻译) - Deleted voice option
          _buildSegmentSelector(context),
          const SizedBox(height: 24),

          // B. Language Selector Row with Swap Button
          _buildLanguageSelector(context, provider),
          const SizedBox(height: 16),

          // 🤖 Active Model and 🕵️ Incognito Status indicator Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Active Model Badge
              Row(
                children: [
                  Icon(Icons.memory_rounded, size: 16, color: primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    '离线模型: ${provider.activeDefaultModel.name}',
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Incognito Status
              if (provider.isIncognito)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade700.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security_rounded, size: 12, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '无痕模式已开启',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // C. Core action content (depends on the selected segment mode)
          _buildCoreActionContainer(context, provider),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==================== SUB-COMPONENTS ====================

  // Segment mode switcher (即时翻译, 文本翻译) - Only 2 tabs now!
  Widget _buildSegmentSelector(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> segments = [
      {'icon': Icons.swap_horiz_rounded, 'name': '即时翻译'},
      {'icon': Icons.notes_rounded, 'name': '文本翻译'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(segments.length, (index) {
          final isSelected = _selectedSegmentIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSegmentIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      segments[index]['icon'],
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      segments[index]['name'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Language selectors card (🇨🇳 中文, 🇺🇸 English cards + Swap button)
  Widget _buildLanguageSelector(BuildContext context, TranslationProvider provider) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String srcLangName = provider.sourceLang == 'zh'
        ? '🇨🇳 中文'
        : (provider.sourceLang == 'en' ? '🇺🇸 English' : '🌐 ' + provider.sourceLang.toUpperCase());
    final String targetLangName = provider.targetLang == 'zh'
        ? '🇨🇳 中文'
        : (provider.targetLang == 'en' ? '🇺🇸 English' : '🌐 ' + provider.targetLang.toUpperCase());

    return Row(
      children: [
        // Source card
        Expanded(
          child: _buildLanguageCard(
            context,
            label: srcLangName,
            isDark: isDark,
            onTap: () => _showLanguageSelectDialog(context, provider, isSource: true),
          ),
        ),

        // Swap bubble
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
              onPressed: () {
                provider.swapLanguages();
              },
            ),
          ),
        ),

        // Target card
        Expanded(
          child: _buildLanguageCard(
            context,
            label: targetLangName,
            isDark: isDark,
            onTap: () => _showLanguageSelectDialog(context, provider, isSource: false),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageCard(
    BuildContext context, {
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(16),
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
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Core action container switches between Instant Translation and Text Translation
  Widget _buildCoreActionContainer(BuildContext context, TranslationProvider provider) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // SEGMENT 0: INSTANT TRANSLATION (即时翻译 - Onboarding/Start Screen)
    if (_selectedSegmentIndex == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
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
          children: [
            // Circular Mic Visual
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic_rounded, color: primaryColor, size: 42),
            ),
            const SizedBox(height: 20),
            const Text(
              '即时翻译运行准备',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮，系统将开启保活后台，进入高保真免触碰实时通话监听状态。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: '开启即时监听',
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                if (!provider.activeDefaultModel.isDownloaded) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                          SizedBox(width: 8),
                          Text('翻译大模型未就绪'),
                        ],
                      ),
                      content: Text('当前默认的大模型「${provider.activeDefaultModel.name}」尚未下载，无法进行本地离线即时语音翻译。\n\n请前往「模型管理」下载该大模型后重试。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ModelManagementScreen()),
                            );
                          },
                          child: const Text('去下载', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                setState(() {
                  _isInstantActive = true;
                  _startInstantSimulation(provider);
                });
              },
            ),

          ],
        ),
      );
    }

    // SEGMENT 1: TEXT TRANSLATION (文本翻译 - Premium Screen matching user's screenshot)
    else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. INPUT CONTAINER CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _textController,
                  maxLines: 6,
                  minLines: 4,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                  decoration: InputDecoration(
                    hintText: '输入或粘贴要翻译的文本...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey.shade600 : const Color(0xFF9CA3AF),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (text) {
                    setState(() {});
                    _onTextChanged(text, provider);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // A. Model Badge (e.g. ● Qwen2.5-1.5B)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            provider.activeDefaultModel.name,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // B. Operations Button (Trash, Camera, Gallery)
                    Row(
                      children: [
                        if (_textController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade500, size: 22),
                            onPressed: () {
                              setState(() {
                                _textController.clear();
                              });
                              provider.translateText('');
                            },
                          ),
                        IconButton(
                          icon: Icon(Icons.camera_alt_outlined, color: Colors.grey.shade500, size: 22),
                          onPressed: () {
                            _showMockDialog(context, '拍照翻译', '正在启动系统相机拍摄画面...\n[模拟：成功识别取景框文字并翻译]');
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.image_outlined, color: Colors.grey.shade500, size: 22),
                          onPressed: () {
                            _showMockDialog(context, '图片导入翻译', '正在调取相册并启动 OCR 识别...\n[模拟：成功提取图片文字并自动输入]');
                          },
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. OUTPUT CONTAINER CARD (Solid Theme Purple Card)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '翻译结果',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Show Translation Content or Empty translation placeholder matching screenshot
                Text(
                  provider.isLoading
                      ? '正在离线翻译中...'
                      : (provider.errorMessage.isNotEmpty
                          ? provider.errorMessage
                          : (provider.currentTranslation.isNotEmpty
                              ? provider.currentTranslation
                              : 'Translation will appear here...')),
                  style: TextStyle(
                    color: provider.errorMessage.isNotEmpty
                        ? Colors.amber.shade200
                        : Colors.white,
                    fontSize: provider.errorMessage.isNotEmpty ? 15 : 18,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),


                const SizedBox(height: 24),

                // Copy & Share Action Buttons at the bottom
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Copy
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: provider.currentTranslation.isEmpty
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已成功复制译文到剪贴板！')),
                                );
                              },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.content_copy_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                '复制',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Share
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: provider.currentTranslation.isEmpty
                            ? null
                            : () {
                                _showMockDialog(context, '分享翻译结果', '分享渠道:\n1. 微信 (WeChat)\n2. QQ\n3. 系统分享\n[已模拟拉取微信分享包]');
                              },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.reply_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                '分享',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. BOTTOM TIP BAR
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, color: primaryColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  '支持拍照翻译 · 识别图片中的文字并翻译',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  // ==================== IMMERSIVE INSTANT TRANSLATION FOCUSED SCREEN ====================
  // Perfect adaptive design wiring up BOTH dynamic Day & Night modes!
  Widget _buildFocusedInstantScreen(
    BuildContext context,
    TranslationProvider provider,
    Color primaryColor,
    bool isDark,
  ) {
    // 1. Core aesthetic color tokens dynamically determined by Day/Night state
    final Color bgColor = isDark ? const Color(0xFF0F0E1E) : const Color(0xFFF9F8FD);
    final Color keeperBg = isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEDE9FE);
    final Color keeperTextColor = isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED);
    
    final Color spokenCardBg = isDark ? const Color(0xFF221E52) : const Color(0xFFF0EFF8);
    final Color spokenTextColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final Color spokenDotColor = primaryColor;
    
    final Color transCardBg = primaryColor; // Solid dynamic theme purple for output
    
    final Color btnBg = isDark ? const Color(0xFF221E52) : const Color(0xFFF0EFF8);
    final Color btnIconColor = isDark ? Colors.white : primaryColor;

    // Language flag emojis
    final String srcEmoji = provider.sourceLang == 'zh' ? '🇨🇳' : '🇺🇸';
    final String targetEmoji = provider.targetLang == 'zh' ? '🇨🇳' : '🇺🇸';

    // Wave color turns glowing green when vocal sound is detected by simulation
    final Color waveColor = _isSoundDetected
        ? const Color(0xFF10B981) // Neon Green
        : (isDark ? const Color(0xFFA855F7) : primaryColor); // Elegant Purple

    return Container(
      color: bgColor,
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A. Top status alert pill (Keeper alert)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: keeperBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_in_talk_rounded, color: keeperTextColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '应用保活中 · 即时翻译运行中',
                    style: TextStyle(
                      color: keeperTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // B. Flag Indicators Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  srcEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 20),
                Icon(
                  Icons.swap_horiz_rounded,
                  color: isDark ? Colors.white70 : Colors.black45,
                  size: 24,
                ),
                const SizedBox(width: 20),
                Text(
                  targetEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // C. Overlay Sine Vocal Wave Animation in the center
            SizedBox(
              height: 120,
              child: AnimatedBuilder(
                animation: _waveController!,
                builder: (context, child) {
                  return CustomPaint(
                    painter: VocalWavePainter(
                      phase: _waveController!.value * 2 * math.pi,
                      amplitude: _isSoundDetected ? 26.0 : 8.0,
                      color: waveColor,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // D. Spoken Text Card (Card 1)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: spokenCardBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: spokenDotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.sourceLang == 'zh' ? '你说的 · 中文' : 'You said · English',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black45,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _simulatedSpoken.isNotEmpty
                        ? _simulatedSpoken
                        : (_isPaused ? '即时翻译已暂停' : '正在聆听您的说话声音...'),
                    style: TextStyle(
                      color: _simulatedSpoken.isNotEmpty
                          ? spokenTextColor
                          : (isDark ? Colors.white30 : Colors.black38),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      fontStyle: _simulatedSpoken.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // E. Translated Text Card (Card 2) - Solid Purple Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: transCardBg,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: transCardBg.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981), // Glowing Green
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.sourceLang == 'zh' ? '翻译 · English' : 'Translation · 中文',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _simulatedTranslated.isNotEmpty
                        ? _simulatedTranslated
                        : 'Translation will appear here...',
                    style: TextStyle(
                      color: _simulatedTranslated.isNotEmpty
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 54),

            // F. Bottom Operations Bar (Pause, Huge Glowing Mic, Stop/Close)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 1. Pause / Resume Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPaused = !_isPaused;
                      if (_isPaused) {
                        _waveController?.stop();
                      } else {
                        _waveController?.repeat();
                      }
                    });
                  },
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: btnBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: btnIconColor,
                      size: 26,
                    ),
                  ),
                ),

                // 2. Huge Centered Mic Button (Glowing Neon Green on Sound Detection)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _isSoundDetected
                            ? const Color(0xFF10B981).withOpacity(0.6) // glowing neon green shadow
                            : primaryColor.withOpacity(0.35),
                        blurRadius: _isSoundDetected ? 24 : 14,
                        spreadRadius: _isSoundDetected ? 6 : 2,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                // 3. Stop / Exit Button (Red Cross)
                GestureDetector(
                  onTap: () {
                    _stopInstantSimulation();
                  },
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444), // Vibrant Red
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Language selectors picker dialog
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

  // Easy UI mock alerts
  void _showMockDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          )
        ],
      ),
    );
  }
}

// ==================== HOLOGRAPHIC OVERLAPPING WAVE CUSTOM PAINTER ====================
class VocalWavePainter extends CustomPainter {
  final double phase;
  final double amplitude;
  final Color color;

  VocalWavePainter({
    required this.phase,
    required this.amplitude,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;

    // Draw overlapping sin wave 1 (Primary wave, larger, thicker)
    final paint1 = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path1 = Path();
    path1.moveTo(0, midY);
    for (double x = 0; x <= size.width; x += 1.0) {
      final y = midY + amplitude * math.sin((x / size.width) * 2 * math.pi * 1.5 - phase);
      path1.lineTo(x, y);
    }
    canvas.drawPath(path1, paint1);

    // Draw overlapping sin wave 2 (Holographic secondary wave, offset, thinner)
    final paint2 = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final path2 = Path();
    path2.moveTo(0, midY);
    for (double x = 0; x <= size.width; x += 1.0) {
      final y = midY + (amplitude * 0.75) * math.sin((x / size.width) * 2 * math.pi * 1.8 + phase + math.pi / 2);
      path2.lineTo(x, y);
    }
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant VocalWavePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.color != color;
  }
}
