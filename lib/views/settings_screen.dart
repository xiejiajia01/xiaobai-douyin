import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../services/theme_service.dart';
import '../services/word_service.dart';
import '../services/api_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'privacy_settings_screen.dart';
import 'login_screen.dart';

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
  final ValueNotifier<int> _countdownNotifier = ValueNotifier<int>(0);
  Timer? _countdownTimer;
  static const String _lastGenerateTimeKey = 'last_generate_time';
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initCountdown();
  }

  Future<void> _initCountdown() async {
    final prefs = await SharedPreferences.getInstance();
    final lastGenerateTime = prefs.getInt(_lastGenerateTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastGenerateTime;
    
    if (diff < 60000) { // 60秒内
      final remainingSeconds = ((60000 - diff) / 1000).floor();
      _countdownNotifier.value = remainingSeconds;
      _startRegenerateCountdown();
    }
  }

  void _startRegenerateCountdown() async {
    if (_countdownNotifier.value <= 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastGenerateTimeKey, DateTime.now().millisecondsSinceEpoch);
      _countdownNotifier.value = 60;
    }
    
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownNotifier.value > 0) {
        _countdownNotifier.value--;
        if (_countdownNotifier.value == 0) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_lastGenerateTimeKey);
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<bool> _canGenerate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastGenerateTime = prefs.getInt(_lastGenerateTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastGenerateTime) >= 60000; // 60秒后才能重新生成
  }

  Future<int> _getRemainingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastGenerateTime = prefs.getInt(_lastGenerateTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastGenerateTime;
    if (diff < 60000) {
      return ((60000 - diff) / 1000).floor();
    }
    return 0;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownNotifier.dispose();
    _audioPlayer.dispose();
    super.dispose();
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
                  const SizedBox(height: 16),
                  _buildPrivacyPermissionItem(currentTheme),
                  const SizedBox(height: 16),
                  _buildThirdPartyListItem(currentTheme),
                  const SizedBox(height: 40),
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

  void _showDailySentenceDialog(BuildContext context, AppThemeMode currentTheme) async {
    final apiService = ApiService();
    final prefs = await SharedPreferences.getInstance();
    final isWomanVoice = prefs.getBool('isWomanVoice') ?? false;
    final sentence = await apiService.getDailySentence();
    
    // 预下载音频
    String? audioPath;
    try {
      print('开始预下载音频');
      audioPath = await apiService.getSentenceAudioPath(
        sentence['en'] ?? '',
        isWomanVoice ? 'female' : 'male',
      );
      print('音频预下载完成: $audioPath');
    } catch (e) {
      print('音频预下载失败: $e');
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: currentTheme == AppThemeMode.dark 
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFF5F5F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      sentence['en'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: () async {
                      try {
                        // 如果预下载失败，重试下载
                        if (audioPath == null) {
                          print('预下载失败，重试下载');
                          audioPath = await apiService.getSentenceAudioPath(
                            sentence['en'] ?? '',
                            isWomanVoice ? 'female' : 'male',
                          );
                          print('重试下载成功: $audioPath');
                        }
                        
                        // 停止当前播放
                        await _audioPlayer.stop();
                        
                        // 设置音频源并播放
                        await _audioPlayer.setFilePath(audioPath!);
                        await _audioPlayer.play();
                        print('开始播放音频');
                      } catch (e) {
                        print('音频播放失败: $e');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('播放失败：$e'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                sentence['cn'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: currentTheme == AppThemeMode.dark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    '关闭',
                    style: TextStyle(
                      fontSize: 16,
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

  Widget _buildDailySentenceItem(AppThemeMode currentTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: _getCardColor(currentTheme),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => _showDailySentenceDialog(context, currentTheme),
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
          onTap: () => _showAIWritingDialog(currentTheme),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
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

  Future<void> _showAIWritingDialog(AppThemeMode currentTheme) async {
    // 检查是否可以生成
    if (!await _canGenerate()) {
      final remainingTime = await _getRemainingTime();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: currentTheme == AppThemeMode.dark ? Colors.black87 : Colors.white,
          title: Text(
            '提示',
            style: TextStyle(
              color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
            ),
          ),
          content: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Text(
              '您的操作太频繁了，请等待${remainingTime}秒后再试',
              style: TextStyle(
                fontSize: 14,
                color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }

    final wordService = await WordService.create();
    final apiService = ApiService();
    
    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: currentTheme == AppThemeMode.dark ? Colors.black87 : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AI创作中，结果仅供参考…',
                          style: TextStyle(
                            fontSize: 14,
                            color: currentTheme == AppThemeMode.dark ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 获取标记的单词
      final markedWords = await wordService.getMarkedWords();
      if (markedWords.isEmpty) {
        Navigator.pop(context); // 关闭加载对话框
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: currentTheme == AppThemeMode.dark ? Colors.black87 : Colors.white,
            title: Text(
              '提示',
              style: TextStyle(
                color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
              ),
            ),
            content: Text(
              '请先在复习模式中标记一些单词',
              style: TextStyle(
                color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
        return;
      }

      // 随机选择30个单词（或全部如果不足30个）
      markedWords.shuffle();
      final selectedWords = markedWords.take(30).map((w) => w.word).toList();

      // 调用AI写作API
      final content = await apiService.generateAIWriting(selectedWords);
      
      // 关闭加载对话框
      Navigator.pop(context);

      // 显示结果对话框
      if (!mounted) return;
      
      // 启动倒计时
      _startRegenerateCountdown();
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: currentTheme == AppThemeMode.dark ? Colors.black87 : Colors.white,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI写作结果',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      content,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _countdownNotifier,
                    builder: (context, countdown, child) {
                      return TextButton(
                        onPressed: countdown > 0 
                          ? null 
                          : () {
                              Navigator.pop(context);
                              _showAIWritingDialog(currentTheme);
                            },
                        style: TextButton.styleFrom(
                          disabledForegroundColor: currentTheme == AppThemeMode.dark 
                              ? Colors.white38 
                              : Colors.black38,
                        ),
                        child: Text(
                          countdown > 0 
                              ? '重新生成 (${countdown}s)' 
                              : '重新生成',
                          style: TextStyle(
                            fontSize: 14,
                            color: countdown > 0
                                ? (currentTheme == AppThemeMode.dark ? Colors.white38 : Colors.black38)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      // 关闭加载对话框（如果存在）
      Navigator.of(context).pop();
      
      // 显示错误对话框
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: currentTheme == AppThemeMode.dark ? Colors.black87 : Colors.white,
          title: Text(
            '生成失败',
            style: TextStyle(
              color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            e.toString(),
            style: TextStyle(
              color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPrivacyPermissionItem(AppThemeMode currentTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: _getCardColor(currentTheme),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PrivacySettingsScreen(currentTheme: currentTheme),
              ),
            );
          },
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                ),
                const SizedBox(width: 16),
                Text(
                  '隐私设置',
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

  Widget _buildThirdPartyListItem(AppThemeMode currentTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: _getCardColor(currentTheme),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => _showThirdPartyListDialog(currentTheme),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.integration_instructions,
                  color: currentTheme == AppThemeMode.dark ? Colors.white : ThemeColors.blackText,
                ),
                const SizedBox(width: 16),
                Text(
                  '第三方合作清单',
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

  void _showThirdPartyListDialog(AppThemeMode currentTheme) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: currentTheme == AppThemeMode.dark ? Colors.black87 : Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        '第三方合作清单',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '为保障小白单词App相关功能的实现与应用的安全稳定运行，我们可能会接入由第三方提供的软件开发包（SDK）以实现相关目的。我们会对合作方获取信息的SDK进行严格的安全监测，以保护数据安全。',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: currentTheme == AppThemeMode.dark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSDKSection('认证与授权', [
                        {
                          'name': 'JWT',
                          'purpose': '用于用户认证和token管理',
                          'source': 'golang-jwt',
                          'website': 'https://github.com/golang-jwt/jwt',
                        },
                      ], currentTheme),
                      _buildSDKSection('数据存储', [
                        {
                          'name': 'GORM',
                          'purpose': 'MySQL数据库ORM框架',
                          'source': 'GORM',
                          'website': 'https://gorm.io',
                        },
                        {
                          'name': 'Redis',
                          'purpose': '缓存和临时数据存储',
                          'source': 'Redis',
                          'website': 'https://redis.io',
                        },
                        {
                          'name': 'shared_preferences (^2.3.5)',
                          'purpose': '提供轻量级的键值对存储功能',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/shared_preferences',
                        },
                        {
                          'name': 'sqflite (^2.3.0)',
                          'purpose': 'SQLite 数据库支持',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/sqflite',
                        },
                        {
                          'name': 'path_provider (^2.1.1)',
                          'purpose': '提供应用程序文件路径',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/path_provider',
                        },
                      ], currentTheme),
                      _buildSDKSection('云服务', [
                        {
                          'name': '阿里云SDK',
                          'purpose': '用于阿里云相关服务调用',
                          'source': '阿里巴巴（中国）有限公司',
                          'website': 'https://www.aliyun.com',
                        },
                      ], currentTheme),
                      _buildSDKSection('状态管理', [
                        {
                          'name': 'provider (^6.1.1)',
                          'purpose': '提供基础的状态管理功能',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/provider',
                        },
                        {
                          'name': 'flutter_riverpod (^2.4.9)',
                          'purpose': '提供响应式状态管理，是 provider 的升级版',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/flutter_riverpod',
                        },
                        {
                          'name': 'riverpod_annotation (^2.3.3)',
                          'purpose': '为 Riverpod 提供代码生成支持',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/riverpod_annotation',
                        },
                      ], currentTheme),
                      _buildSDKSection('网络', [
                        {
                          'name': 'dio (^5.4.0)',
                          'purpose': '强大的 HTTP 网络请求库',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/dio',
                        },
                      ], currentTheme),
                      _buildSDKSection('音频', [
                        {
                          'name': 'audioplayers (^5.2.1)',
                          'purpose': '提供音频播放功能',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/audioplayers',
                        },
                        {
                          'name': 'just_audio (^0.9.36)',
                          'purpose': '提供高级音频播放功能',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/just_audio',
                        },
                      ], currentTheme),
                      _buildSDKSection('UI 和动画', [
                        {
                          'name': 'flutter_animate (^4.3.0)',
                          'purpose': '提供丰富的动画效果',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/flutter_animate',
                        },
                        {
                          'name': 'glass_kit (^3.0.0)',
                          'purpose': '提供毛玻璃效果的 UI 组件',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/glass_kit',
                        },
                        {
                          'name': 'scrollable_positioned_list (^0.3.8)',
                          'purpose': '提供可滚动的定位列表组件',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/scrollable_positioned_list',
                        },
                      ], currentTheme),
                      _buildSDKSection('路由', [
                        {
                          'name': 'go_router (^13.0.1)',
                          'purpose': '提供声明式路由管理',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/go_router',
                        },
                      ], currentTheme),
                      _buildSDKSection('系统功能', [
                        {
                          'name': 'permission_handler (^11.1.0)',
                          'purpose': '处理应用权限请求',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/permission_handler',
                        },
                        {
                          'name': 'flutter_local_notifications (^16.3.0)',
                          'purpose': '提供本地通知功能',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/flutter_local_notifications',
                        },
                        {
                          'name': 'timezone (^0.9.2)',
                          'purpose': '处理时区相关功能',
                          'source': 'pub.dev',
                          'website': 'https://pub.dev/packages/timezone',
                        },
                      ], currentTheme),
                      const SizedBox(height: 20),
                      Text(
                        '注意事项：',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. 我们会对SDK进行严格的安全审查，确保用户数据安全\n'
                        '2. SDK可能会因版本升级、策略调整等原因变更其数据处理方式\n'
                        '3. 具体SDK的使用细节和隐私政策请参考各SDK官方文档',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: currentTheme == AppThemeMode.dark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSDKSection(String title, List<Map<String, String>> sdks, AppThemeMode currentTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...sdks.map((sdk) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sdk['name']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: currentTheme == AppThemeMode.dark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '用途：${sdk['purpose']}',
                style: TextStyle(
                  fontSize: 14,
                  color: currentTheme == AppThemeMode.dark ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                '来源：${sdk['source']}',
                style: TextStyle(
                  fontSize: 14,
                  color: currentTheme == AppThemeMode.dark ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                '官网：${sdk['website']}',
                style: TextStyle(
                  fontSize: 14,
                  color: currentTheme == AppThemeMode.dark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        )).toList(),
      ],
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
      
      // 清除本地存储的token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      
      // 返回到登录页面
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      
      // 即使发生错误，也尝试清除本地token并返回登录页
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
      } catch (_) {
        // 忽略清除token时的错误
      }
      
      // 返回登录页
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      
      // 显示错误信息
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
    bool showExpandIcon = true,
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
                if (showExpandIcon)
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