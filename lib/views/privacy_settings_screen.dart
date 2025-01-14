import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/theme_service.dart';
import 'push_settings_screen.dart';
import 'info_collection_list_screen.dart';

class PrivacySettingsScreen extends StatelessWidget {
  final AppThemeMode currentTheme;

  const PrivacySettingsScreen({
    Key? key,
    required this.currentTheme,
  }) : super(key: key);

  Color _getBackgroundColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return Colors.black;
      case AppThemeMode.orange:
        return ThemeColors.orangeBackground;
      case AppThemeMode.green:
        return ThemeColors.greenBackground;
    }
  }

  Color _getCardColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return Colors.white.withOpacity(0.1);
      case AppThemeMode.orange:
        return ThemeColors.orangeCard;
      case AppThemeMode.green:
        return ThemeColors.greenCard;
    }
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    return Material(
      color: _getCardColor(currentTheme),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: currentTheme == AppThemeMode.dark 
                      ? Colors.white 
                      : ThemeColors.blackText,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: currentTheme == AppThemeMode.dark 
                  ? Colors.white.withOpacity(0.5) 
                  : Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(currentTheme),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '隐私设置',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getBackgroundColor(currentTheme),
              _getBackgroundColor(currentTheme),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _getCardColor(currentTheme),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildSettingItem(
                    context,
                    '系统权限管理',
                    () async {
                      await openAppSettings();
                    },
                  ),
                  Divider(
                    height: 1,
                    color: currentTheme == AppThemeMode.dark 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.black.withOpacity(0.1),
                  ),
                  _buildSettingItem(
                    context,
                    '个性化推送',
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PushSettingsScreen(
                            currentTheme: currentTheme,
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(
                    height: 1,
                    color: currentTheme == AppThemeMode.dark 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.black.withOpacity(0.1),
                  ),
                  _buildSettingItem(
                    context,
                    '个人信息收集清单',
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => InfoCollectionListScreen(
                            currentTheme: currentTheme,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 