import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/theme_provider.dart';
import '../../logic/providers/translation_provider.dart';
import '../screens/model_management_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final translationProvider = context.watch<TranslationProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0F0E1E) : const Color(0xFFF9F8FD),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // 1. Streamlined setting title "偏好与隐私"
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 20),
            child: Text(
              '偏好与隐私',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E1B4B),
              ),
            ),
          ),

          // 2. High-fidelity settings group card
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              children: [
                // A. 无痕模式
                _buildSettingTile(
                  context,
                  icon: Icons.security_rounded,
                  iconColor: Colors.purple.shade400,
                  title: '无痕模式',
                  subtitle: '不保存翻译记录',
                  trailing: Switch(
                    value: translationProvider.isIncognito,
                    onChanged: (val) {
                      translationProvider.toggleIncognitoMode(val);
                    },
                  ),
                ),
                _buildDivider(isDark),

                // B. 夜间模式
                _buildSettingTile(
                  context,
                  icon: Icons.dark_mode_outlined,
                  iconColor: Colors.blue.shade600,
                  title: '夜间模式',
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (val) {
                      themeProvider.toggleDarkMode();
                    },
                  ),
                ),
                _buildDivider(isDark),

                // C. 模型管理
                _buildSettingTile(
                  context,
                  icon: Icons.memory_rounded,
                  iconColor: Colors.pink.shade400,
                  title: '模型管理',
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ModelManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(isDark),

                // D. 文档记录清理 (7天临时保存自动清理)
                _buildSettingTile(
                  context,
                  icon: Icons.auto_delete_outlined,
                  iconColor: Colors.deepOrange.shade400,
                  title: '文档记录清理',
                  subtitle: translationProvider.documentRetentionDays == 7
                      ? '翻译文档只临时保存 7 天'
                      : '文档记录永久保存',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        translationProvider.documentRetentionDays == 7 ? '临时保存7天' : '永久保存',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    ],
                  ),
                  onTap: () {
                    _showRetentionDialog(context, translationProvider);
                  },
                ),
                _buildDivider(isDark),

                // E. 智能内存优化 (大模型后台动态释放)
                _buildSettingTile(
                  context,
                  icon: Icons.bolt_rounded,
                  iconColor: Colors.green.shade500,
                  title: '智能内存优化',
                  subtitle: '自动释放后台模型驻留内存',
                  trailing: Switch(
                    value: translationProvider.isMemoryOptimized,
                    activeColor: Colors.green.shade500,
                    onChanged: (val) {
                      translationProvider.toggleMemoryOptimized(val);
                      if (val) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('⚡ 智能内存优化已生效，应用后台运行时将释放 1.2GB 大模型占用！')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- REUSABLE UTILITIES ---

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Left Icon Badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Title & Subtitle column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Trailing Widget
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade100,
      indent: 64,
    );
  }

  // Retention Period Selector Alert Dialog
  void _showRetentionDialog(BuildContext context, TranslationProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('设置文档记录保留期限'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<int>(
                title: const Text('只保留最近 7 天文档 (临时保存)'),
                subtitle: const Text('推荐，节省手机本地存储'),
                value: 7,
                groupValue: provider.documentRetentionDays,
                onChanged: (val) {
                  provider.setDocumentRetentionDays(val!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<int>(
                title: const Text('永久保存文档记录'),
                subtitle: const Text('数据将无限期保存在本设备'),
                value: 0,
                groupValue: provider.documentRetentionDays,
                onChanged: (val) {
                  provider.setDocumentRetentionDays(val!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
