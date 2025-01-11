import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/theme_service.dart';
import '../services/word_service.dart';
import '../services/api_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isWomanVoice = false;
  bool _isVoiceExpanded = false;
  bool _isThemeExpanded = false;
  bool _isReviewMode = false;
  bool _isReviewExpanded = false;
  bool _settingsChanged = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final wordService = await WordService.create();
    final isReviewMode = await wordService.getReviewMode();
    setState(() {
      _isWomanVoice = prefs.getBool('isWomanVoice') ?? false;
      _isReviewMode = isReviewMode;
    });
  }

  Future<void> _saveVoiceSettings(bool isWoman) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isWomanVoice', isWoman);
    setState(() {
      _isWomanVoice = isWoman;
      _isVoiceExpanded = false;
    });
  }

  Future<void> _saveReviewMode(bool enabled) async {
    final wordService = await WordService.create();
    await wordService.setReviewMode(enabled);
    setState(() {
      _isReviewMode = enabled;
      _settingsChanged = true;
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
    final currentTheme = ref.watch(themeNotifierProvider);
    
    return Scaffold(
      backgroundColor: _getBackgroundColor(currentTheme),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '自定义',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, 
            color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText
          ),
          onPressed: () => Navigator.of(context).pop(_settingsChanged),
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
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 16),
                  _buildVoiceSettingItem(currentTheme),
                  const SizedBox(height: 16),
                  _buildThemeSettingItem(currentTheme),
                  const SizedBox(height: 16),
                  _buildPhoneticAndPartOfSpeechItem(currentTheme),
                  const SizedBox(height: 16),
                  _buildReviewModeItem(currentTheme),
                  const SizedBox(height: 16),
                  _buildLearningProgressItem(currentTheme),
                  const SizedBox(height: 40),
                  _buildDailySentenceItem(currentTheme),
                  const SizedBox(height: 16),
                  _buildAIWritingItem(currentTheme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: _buildLogoutButton(currentTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSettingItem(AppThemeMode currentTheme) {
    return Column(
      children: [
        _buildSettingHeader(
          icon: Icons.record_voice_over,
          title: '音色',
          isExpanded: _isVoiceExpanded,
          onTap: () => setState(() => _isVoiceExpanded = !_isVoiceExpanded),
          currentTheme: currentTheme,
        ),
        if (_isVoiceExpanded)
          _buildVoiceOptions(currentTheme),
      ],
    );
  }

  Widget _buildThemeSettingItem(AppThemeMode currentTheme) {
    return Column(
      children: [
        _buildSettingHeader(
          icon: Icons.color_lens,
          title: '主题',
          isExpanded: _isThemeExpanded,
          onTap: () => setState(() => _isThemeExpanded = !_isThemeExpanded),
          currentTheme: currentTheme,
        ),
        if (_isThemeExpanded)
          _buildThemeOptions(currentTheme),
      ],
    );
  }

  Widget _buildPhoneticAndPartOfSpeechItem(AppThemeMode currentTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: _getCardColor(currentTheme),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => _showPhoneticAndPartOfSpeechDialog(context, currentTheme),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.menu_book,
                  color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                ),
                const SizedBox(width: 16),
                Text(
                  '音标·词性',
                  style: TextStyle(
                    fontSize: 16,
                    color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPhoneticAndPartOfSpeechDialog(BuildContext context, AppThemeMode currentTheme) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: currentTheme == AppThemeMode.dark 
            ? const Color(0xFF1A1A1A)  // 深色主题背景
            : const Color(0xFFF5F5F0),  // 浅色主题背景
        insetPadding: EdgeInsets.zero, // 设置为零以实现全屏效果
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      '音标·词性说明',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // 为了保持标题居中
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '''10种英语词性说明
英语词性有10种，另有2种特殊词性 分别是及物、不及物。
如果看到indefinite (不定性词类)，preposition (介词)，conjunction (连词)，interjection (感叹词)，这些词性，不要翻译，直接跳过。

10种词性：
1、名词(n.)，Nouns 表示人或事物的名称 box, pen,tree,apple
2、代词(pron.)，Pronouns 代替名词、数词、形容词We, this, them,myself
3、形容词(adj.)， Adjectives 用来修饰名词，表示人或事物的特征 good, sad, high, short
4、数词(num.)，Numerals表示数目或顺序 one,two, first
5、动词(v.)，Verb 表示动作或状态 Jump,sing,visit
6、副词(adv.)，Adverbs 修饰动、形、副等词，表示动作特征 there,widely,suddenly
7、冠词(art.)，Articles 用在名词前，帮助说明名词所指的范围 a, an, the
8、介词(prep.)，Prepositions 用在名词或代词前，说明它与别的词的关系 in,on,down,up
9、连词(conj.)，Conjunctions 表示人或事物的名称if,because,but
10、感叹词(int.)， Interjections 代替名词、数词、形容词等 oh,hello,hi,yeah

特殊词性——及物、不及物：
vt.是及物动词，vt.后必须跟宾语：sing a song
vi.是不及物动词，vi.后不直接带宾语或不带宾语:jump high


48个英语音标表
8个英语音标表：20个元音+28个辅音

一、单元音12个
短元音： [i] [ə] [ɒ] [u] [Λ] [æ] [e]
长元音： [i:] [ə:] [ɔ:] [u:] [ɑ:]

二、双元音8个
[ai] [ei] [ɔi] [au] [əu] [iə] [eə] [uə]

元音和辅音最主要的区别
元音主要靠声带发音 有声调 气流通过喉头、口腔不受阻碍
辅音主要是用气流与牙齿舌头等其它器官摩擦发音 气流通过喉头、口腔要受到某个部位的阻碍

三、清浊成对的辅音10对
清辅音：[p] [t] [k] [f] [θ] [s] [tr] [ts] [∫] [t∫]
浊辅音：[b] [d] [g] [v] [ð] [z] [dr] [dz] [ʒ] [dʒ]

四、其他辅音8个
[h] [m ] [n] [ŋ] [l] [r] [w] [j]

以上：如果看不懂 ，可以往上找个视频看看，会很简单的，加油！''',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewModeItem(AppThemeMode currentTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: _getCardColor(currentTheme),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.repeat,
                color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
              ),
              const SizedBox(width: 16),
              Text(
                '复习模式',
                style: TextStyle(
                  fontSize: 16,
                  color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                ),
              ),
              const Spacer(),
              Switch(
                value: _isReviewMode,
                onChanged: _saveReviewMode,
                activeColor: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLearningProgressItem(AppThemeMode currentTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: _getCardColor(currentTheme),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
              ),
              const SizedBox(width: 16),
              Text(
                '学习进度',
                style: TextStyle(
                  fontSize: 16,
                  color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                ),
              ),
              const Spacer(),
              FutureBuilder<(int, int)>(
                future: WordService.create().then((service) => service.getLearningProgress()),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  final (marked, total) = snapshot.data!;
                  final percentage = (marked / total * 100).toStringAsFixed(1);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F0), // 米色背景
                      borderRadius: BorderRadius.circular(20), // 椭圆形效果
                    ),
                    child: Text(
                      '$marked/$total ($percentage%)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailySentenceItem(AppThemeMode currentTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: _getCardColor(currentTheme),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => _showFeatureDialog(context, currentTheme),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.format_quote,
                  color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                ),
                const SizedBox(width: 16),
                Text(
                  '今日佳句',
                  style: TextStyle(
                    fontSize: 16,
                    color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIWritingItem(AppThemeMode currentTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: _getCardColor(currentTheme),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => _showFeatureDialog(context, currentTheme),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.edit,
                  color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                ),
                const SizedBox(width: 16),
                Text(
                  'AI写作',
                  style: TextStyle(
                    fontSize: 16,
                    color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFeatureDialog(BuildContext context, AppThemeMode currentTheme) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: currentTheme == AppThemeMode.dark 
            ? const Color(0xFFF5F5F0)  // 深色主题使用米白色
            : _getBackgroundColor(currentTheme),  // 其他主题使用对应背景色
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
          child: Text(
            'hello 小白',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AppThemeMode currentTheme) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 3,
        child: ElevatedButton(
          onPressed: _handleLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFBB2649),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text(
            '退出登录',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      final apiService = ApiService();
      await apiService.logout();
      
      if (!mounted) return;
      
      // 返回到登录页面
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('退出登录失败：$e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildSettingHeader({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required AppThemeMode currentTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: _getCardColor(currentTheme),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                  ),
                ),
                const Spacer(),
                Icon(
                  isExpanded ? Icons.expand_more : Icons.arrow_forward_ios,
                  size: isExpanded ? 24 : 16,
                  color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceOptions(AppThemeMode currentTheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 4),
      child: Material(
        color: _getCardColor(currentTheme).withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
        child: Column(
          children: [
            _buildOptionItem(
              title: '男声',
              isSelected: !_isWomanVoice,
              onTap: () => _saveVoiceSettings(false),
              currentTheme: currentTheme,
            ),
            Divider(
              height: 1,
              color: currentTheme == AppThemeMode.dark ? Colors.white24 : Colors.black12,
            ),
            _buildOptionItem(
              title: '女声',
              isSelected: _isWomanVoice,
              onTap: () => _saveVoiceSettings(true),
              currentTheme: currentTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOptions(AppThemeMode currentTheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 4),
      child: Material(
        color: _getCardColor(currentTheme).withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
        child: Column(
          children: [
            _buildOptionItem(
              title: '深色主题',
              isSelected: currentTheme == AppThemeMode.dark,
              onTap: () {
                ref.read(themeNotifierProvider.notifier).setTheme(AppThemeMode.dark);
                setState(() => _isThemeExpanded = false);
              },
              currentTheme: currentTheme,
            ),
            Divider(
              height: 1,
              color: currentTheme == AppThemeMode.dark ? Colors.white24 : Colors.black12,
            ),
            _buildOptionItem(
              title: '橙色主题',
              isSelected: currentTheme == AppThemeMode.orange,
              onTap: () {
                ref.read(themeNotifierProvider.notifier).setTheme(AppThemeMode.orange);
                setState(() => _isThemeExpanded = false);
              },
              currentTheme: currentTheme,
            ),
            Divider(
              height: 1,
              color: currentTheme == AppThemeMode.dark ? Colors.white24 : Colors.black12,
            ),
            _buildOptionItem(
              title: '绿色主题',
              isSelected: currentTheme == AppThemeMode.green,
              onTap: () {
                ref.read(themeNotifierProvider.notifier).setTheme(AppThemeMode.green);
                setState(() => _isThemeExpanded = false);
              },
              currentTheme: currentTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required AppThemeMode currentTheme,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check,
                color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
              ),
          ],
        ),
      ),
    );
  }
} 