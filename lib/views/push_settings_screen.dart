import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/push_service.dart';

class PushSettingsScreen extends StatefulWidget {
  final AppThemeMode currentTheme;

  const PushSettingsScreen({
    Key? key,
    required this.currentTheme,
  }) : super(key: key);

  @override
  State<PushSettingsScreen> createState() => _PushSettingsScreenState();
}

class _PushSettingsScreenState extends State<PushSettingsScreen> {
  final _pushService = PushService();
  bool _isPushEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _pushService.isPushEnabled();
    setState(() {
      _isPushEnabled = enabled;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(widget.currentTheme),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '个性化推送',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: widget.currentTheme == AppThemeMode.dark 
              ? Colors.white 
              : ThemeColors.blackText,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: widget.currentTheme == AppThemeMode.dark 
              ? Colors.white 
              : ThemeColors.blackText,
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
              _getBackgroundColor(widget.currentTheme),
              _getBackgroundColor(widget.currentTheme),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _getCardColor(widget.currentTheme),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '每日佳句推送',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: widget.currentTheme == AppThemeMode.dark 
                                    ? Colors.white 
                                    : ThemeColors.blackText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '每天7:00和20:00为您推送精选佳句',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.currentTheme == AppThemeMode.dark 
                                    ? Colors.white70 
                                    : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isPushEnabled,
                          onChanged: (value) async {
                            await _pushService.setPushEnabled(value);
                            setState(() {
                              _isPushEnabled = value;
                            });
                          },
                          activeColor: widget.currentTheme == AppThemeMode.dark 
                            ? Colors.white 
                            : ThemeColors.blackText,
                        ),
                      ],
                    ),
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