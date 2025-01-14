import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class InfoCollectionListScreen extends StatelessWidget {
  final AppThemeMode currentTheme;

  const InfoCollectionListScreen({
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

  @override
  Widget build(BuildContext context) {
    final textColor = currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText;
    final subtextColor = currentTheme == AppThemeMode.dark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: _getBackgroundColor(currentTheme),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '小白单词已收集个人信息清单',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: textColor,
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '在您使用小白单词的过程中，我们会收集您在使用APP时产生的一些个人信息。我们已收集的个人信息已在如下清单中列明。',
                  style: TextStyle(
                    fontSize: 14,
                    color: subtextColor,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: _getCardColor(currentTheme),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: currentTheme == AppThemeMode.dark 
                          ? Colors.white.withOpacity(0.1) 
                          : Colors.black.withOpacity(0.1),
                      ),
                      child: DataTable(
                        headingTextStyle: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        dataTextStyle: TextStyle(
                          color: subtextColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        columnSpacing: 24,
                        horizontalMargin: 16,
                        dataRowMinHeight: 80,
                        dataRowMaxHeight: 120,
                        columns: const [
                          DataColumn(label: Text('功能/业务场景')),
                          DataColumn(label: Text('信息种类')),
                          DataColumn(label: Text('使用目的')),
                        ],
                        rows: [
                          DataRow(cells: [
                            DataCell(Container(
                              width: 120,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('登录/注册小白单词账号', softWrap: true),
                            )),
                            DataCell(Container(
                              width: 180,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('手机号、验证码', softWrap: true),
                            )),
                            DataCell(Container(
                              width: 150,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('用于注册创建账号或登录', softWrap: true),
                            )),
                          ]),
                          DataRow(cells: [
                            DataCell(Container(
                              width: 120,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('使用单词学习功能', softWrap: true),
                            )),
                            DataCell(Container(
                              width: 180,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('学习进度信息、标记状态、复习记录等学习行为信息', softWrap: true),
                            )),
                            DataCell(Container(
                              width: 150,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('记录和保存用户的学习数据，提供针对性的学习服务', softWrap: true),
                            )),
                          ]),
                          DataRow(cells: [
                            DataCell(Container(
                              width: 120,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('使用发音功能', softWrap: true),
                            )),
                            DataCell(Container(
                              width: 180,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('语音播放记录、音色偏好设置', softWrap: true),
                            )),
                            DataCell(Container(
                              width: 150,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('提供男声/女声发音服务，优化用户学习体验', softWrap: true),
                            )),
                          ]),
                          DataRow(cells: [
                            DataCell(Container(
                              width: 120,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('使用AI写作功能', softWrap: true),
                            )),
                            DataCell(Container(
                              width: 180,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('用户标记的单词信息、生成的文本内容', softWrap: true),
                            )),
                            DataCell(Container(
                              width: 150,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('基于用户已学习的单词提供AI写作服务', softWrap: true),
                            )),
                          ]),
                          DataRow(cells: [
                            DataCell(Container(
                              width: 120,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('使用今日佳句功能', softWrap: true),
                            )),
                            DataCell(Container(
                              width: 180,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('音频缓存信息、播放记录', softWrap: true),
                            )),
                            DataCell(Container(
                              width: 150,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('提供每日英语句子学习和音频播放服务', softWrap: true),
                            )),
                          ]),
                          DataRow(cells: [
                            DataCell(Container(
                              width: 120,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('使用主题设置', softWrap: true),
                            )),
                            DataCell(Container(
                              width: 180,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('用户界面偏好设置（深色/橙色/绿色主题）', softWrap: true),
                            )),
                            DataCell(Container(
                              width: 150,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('保存用户的界面显示偏好', softWrap: true),
                            )),
                          ]),
                          DataRow(cells: [
                            DataCell(Container(
                              width: 120,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('使用APP时的必要信息收集', softWrap: true),
                            )),
                            DataCell(Container(
                              width: 180,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('设备信息、网络状态、存储权限、系统日志', softWrap: true),
                            )),
                            DataCell(Container(
                              width: 150,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('用于应用运行、数据存储、网络连接等基础功能的实现', softWrap: true),
                            )),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '权限说明',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '1. 网络权限：用于登录注册、在线发音、AI写作等核心功能\n'
                  '2. 存储权限：用于缓存音频文件，提升使用体验\n'
                  '3. 音频播放权限：用于单词发音和今日佳句的语音播放',
                  style: TextStyle(
                    fontSize: 14,
                    color: subtextColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '信息使用规则',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '1. 信息收集遵循最小必要原则\n'
                  '2. 所有信息仅用于提供服务，不会用于其他用途\n'
                  '3. 用户数据存储采用加密方式\n'
                  '4. 支持用户注销账号时完全删除个人信息',
                  style: TextStyle(
                    fontSize: 14,
                    color: subtextColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '如您对个人信息收集和使用有任何疑问，请联系我们：1284608831@qq.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: subtextColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 