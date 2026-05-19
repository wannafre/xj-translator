import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/translation_provider.dart';

class ModelManagementScreen extends StatelessWidget {
  const ModelManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Harmonious colors matching the high-fidelity UI design
    final Color screenBg = isDark
        ? const Color(0xFF0F0E17)
        : const Color(0xFFF9F8FD);
    final Color titleColor = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF1E1B4B);
    final Color defaultCardBg = isDark
        ? const Color(0xFF5B21B6)
        : const Color(0xFF7E3FF2);

    // Filter list to get available models (excluding the active default model from the main available list)
    final defaultModel = provider.activeDefaultModel;
    final availableModels = provider.offlineModels;

    return Scaffold(
      backgroundColor: screenBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: titleColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '模型管理',
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 1. Active Default Model Card (Top Section)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: defaultCardBg,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: defaultCardBg.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // A. Left Icon Container
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.memory_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // B. Middle Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          defaultModel.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: defaultModel.isDownloaded
                                    ? const Color(0xFF10B981) // Emerald green dot
                                    : const Color(0xFFFBBF24), // Amber warning dot
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              defaultModel.isDownloaded
                                  ? '当前默认'
                                  : '当前默认 (未下载)',
                              style: TextStyle(
                                color: defaultModel.isDownloaded
                                    ? const Color(0xFFD1FAE5)
                                    : const Color(0xFFFEF3C7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // C. Right Size Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      defaultModel.size,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 🏷️ 2. Section Header: 可用模型
            Text(
              '可用模型',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),

            // 🤖 3. List of Available Models
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: availableModels.length,
              itemBuilder: (context, index) {
                final model = availableModels[index];
                final isCurrentDefault = provider.defaultModelId == model.id;

                // Determine custom color, icon & background matching the type
                IconData modelIcon = Icons.memory_rounded;
                Color modelThemeColor = const Color(
                  0xFF7E3FF2,
                ); // default purple
                if (model.type == 'mic') {
                  modelIcon = Icons.mic_rounded;
                  modelThemeColor = const Color(0xFF0D9488); // teal
                } else if (model.type == 'globe') {
                  modelIcon = Icons.language_rounded;
                  modelThemeColor = const Color(0xFFD97706); // orange/amber
                }

                return GestureDetector(
                  onTap: () {
                    // Tap on the downloaded card opens action sheet
                    if (model.isDownloaded) {
                      _showModelActionsBottomSheet(context, provider, model);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF181725) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // A. Left Icon Container
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: modelThemeColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            modelIcon,
                            color: modelThemeColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // B. Middle Info Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                model.subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // C. Right Actions Button
                        _buildActionButton(
                          context,
                          provider,
                          model,
                          modelThemeColor,
                          isCurrentDefault,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Dynamic Action Button Renderer ---
  Widget _buildActionButton(
    BuildContext context,
    TranslationProvider provider,
    OfflineModel model,
    Color themeColor,
    bool isCurrentDefault,
  ) {
    // 1. Is currently downloading
    if (model.isDownloading) {
      return Container(
        width: 78,
        height: 36,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                value: model.downloadProgress,
                strokeWidth: 2,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(model.downloadProgress * 100).toInt()}%',
              style: TextStyle(
                color: themeColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // 2. Is downloaded
    if (model.isDownloaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrentDefault
              ? const Color(0xFFECFDF5)
              : (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF065F46).withOpacity(0.3)
                    : const Color(0xFFECFDF5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_rounded,
              color: isCurrentDefault
                  ? const Color(0xFF059669)
                  : const Color(0xFF059669),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              isCurrentDefault ? '默认' : '已下载',
              style: const TextStyle(
                color: Color(0xFF059669),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    // 3. Not downloaded (Render Download Button)
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => provider.downloadModel(model.id),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download_rounded, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text(
                '下载',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Beautiful Customized Bottom Sheet for Downloaded Model Actions ---
  void _showModelActionsBottomSheet(
    BuildContext context,
    TranslationProvider provider,
    OfflineModel model,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCurrentDefault = provider.defaultModelId == model.id;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1B2E) : Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top drag handle indicator
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Model name header
                Text(
                  model.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  model.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),

                // Action 1: Set as Default
                if (!isCurrentDefault) ...[
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFECFDF5),
                      child: Icon(Icons.star_rounded, color: Color(0xFF059669)),
                    ),
                    title: const Text(
                      '设为默认离线翻译模型',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('后续所有本地翻译将优先由该模型执行推理'),
                    onTap: () {
                      provider.setDefaultModel(model.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已成功将 ${model.name} 设为默认模型')),
                      );
                    },
                  ),
                  const Divider(height: 20),
                ],

                // Action 2: Delete (Disabled for core preset Qwen)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: model.id == 'qwen_1.5b'
                        ? Colors.grey.shade100
                        : const Color(0xFFFEF2F2),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: model.id == 'qwen_1.5b'
                          ? Colors.grey
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  title: Text(
                    '删除本地模型文件',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: model.id == 'qwen_1.5b'
                          ? Colors.grey
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  subtitle: Text(
                    model.id == 'qwen_1.5b'
                        ? '核心基线模型不支持删除'
                        : '从手机中清除以释放 ${model.size} 存储空间',
                  ),
                  onTap: model.id == 'qwen_1.5b'
                      ? null
                      : () {
                          Navigator.pop(context);
                          _showDeleteConfirmationDialog(
                            context,
                            provider,
                            model,
                          );
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Confirm Delete Dialog ---
  void _showDeleteConfirmationDialog(
    BuildContext context,
    TranslationProvider provider,
    OfflineModel model,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除模型文件'),
        content: Text('您确定要从本地存储中彻底删除 ${model.name} 吗？删除后在离线状态下将无法使用该模型。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteModel(model.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('已删除模型 ${model.name}')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
}
