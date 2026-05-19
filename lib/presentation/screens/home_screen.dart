import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/theme_provider.dart';
import '../components/capsule_bottom_nav_bar.dart';
import '../tabs/home_tab.dart';
import '../tabs/document_tab.dart';
import '../tabs/profile_tab.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Navigation index: 0 = 首页, 1 = 文档, 2 = 历史, 3 = 我的
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      // Top Navigation Header (Hidden only for History tab which has its own large header)
      appBar: _currentNavIndex == 2
          ? null
          : AppBar(
              toolbarHeight: 70,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  // Logo XJ
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'XJ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title "Soon"
                  Text(
                    'Soon',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              actions: [
                // Quick Theme settings toggle button
                IconButton(
                  icon: const Icon(Icons.palette_outlined, size: 26),
                  onPressed: () {
                    _showThemeSettingsQuickDialog(context, themeProvider);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

      // Pages switching based on bottom navigation
      body: SafeArea(
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            HomeTab(
              onNavigateToTab: (index) {
                setState(() {
                  _currentNavIndex = index;
                });
              },
            ),
            DocumentTab(
              onBackToHome: () {
                setState(() {
                  _currentNavIndex = 0;
                });
              },
            ),
            const HistoryScreen(), // Reused our full HistoryScreen widget here
            const ProfileTab(),
          ],
        ),
      ),

      // Custom capsule-style bottom navigation bar matching the screenshot
      bottomNavigationBar: CapsuleBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
      ),
    );
  }

  // Quick theme dialog accessible from top AppBar palette icon
  void _showThemeSettingsQuickDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('个性主题与偏好'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dark Mode toggle
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('夜间深色模式'),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (val) {
                  themeProvider.toggleDarkMode();
                  Navigator.pop(context);
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Primary colors
            const Text('选择主题色:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: themeProvider.themePalettes.map((palette) {
                final bool isSelected = themeProvider.primaryColor == palette['color'];
                return GestureDetector(
                  onTap: () {
                    themeProvider.setPrimaryColor(palette['color']);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette['color'],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
