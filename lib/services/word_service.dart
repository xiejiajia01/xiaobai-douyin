import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../models/word.dart';

class WordService {
  final SharedPreferences _prefs;
  static const String _markedWordsKey = 'marked_words';
  static const String _bookmarkedWordsKey = 'bookmarked_words';
  List<Word> _words = [];
  bool _isInitialized = false;
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://ntkednawroii.sealosbja.site';

  WordService._(this._prefs);

  static Future<WordService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return WordService._(prefs);
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final String content = await rootBundle.loadString('assets/words/english_words_1_2000.md');
      final List<String> sections = content.split('\n\n');
      
      Set<int> loadedIndices = {};
      List<Word> tempWords = [];
      
      for (String section in sections) {
        if (section.trim().isEmpty) continue;
        
        try {
          final word = Word.fromMarkdown(section);
          tempWords.add(word);
          loadedIndices.add(word.index);
        } catch (e) {
          print('Error parsing section:\n$section');
          print('Error details: $e');
        }
      }

      // 检查缺失的编号
      List<int> missingIndices = [];
      for (int i = 1; i <= 2000; i++) {
        if (!loadedIndices.contains(i)) {
          missingIndices.add(i);
        }
      }

      // 打印加载统计信息
      print('加载完成:');
      print('总计加载: ${tempWords.length} 个单词');
      print('应有单词: 2000 个');
      if (missingIndices.isNotEmpty) {
        print('缺失编号: ${missingIndices.join(', ')}');
      }

      // 按索引排序
      tempWords.sort((a, b) => a.index.compareTo(b.index));
      _words = tempWords;
      _isInitialized = true;
    } catch (e) {
      print('初始化单词服务失败: $e');
      rethrow;
    }
  }

  Future<List<Word>> loadWords() async {
    try {
      final String content = await rootBundle.loadString('assets/words/english_words_1_2000.md');
      final List<String> lines = const LineSplitter().convert(content);
      final List<Word> words = [];
      
      String currentWordContent = '';
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        
        // 如果是空行且有累积的内容，则解析单词
        if (line.isEmpty && currentWordContent.isNotEmpty) {
          try {
            final word = Word.fromMarkdown(currentWordContent);
            word.isMarked = await _getWordMarkState(word.word);
            word.isBookmarked = await _getWordBookmarkState(word.word);
            words.add(word);
          } catch (e) {
            print('Error parsing word content: $currentWordContent');
            print('Error: $e');
          }
          currentWordContent = '';
          continue;
        }
        
        // 如果当前行以数字和点开头，且之前有累积的内容，则解析之前的内容
        if (RegExp(r'^\d+\.').hasMatch(line) && currentWordContent.isNotEmpty) {
          try {
            final word = Word.fromMarkdown(currentWordContent);
            word.isMarked = await _getWordMarkState(word.word);
            word.isBookmarked = await _getWordBookmarkState(word.word);
            words.add(word);
          } catch (e) {
            print('Error parsing word content: $currentWordContent');
            print('Error: $e');
          }
          currentWordContent = line;
        } else {
          // 累积当前行的内容
          if (line.isNotEmpty) {
            currentWordContent += currentWordContent.isEmpty ? line : '\n$line';
          }
        }
      }
      
      // 处理最后一个单词
      if (currentWordContent.isNotEmpty) {
        try {
          final word = Word.fromMarkdown(currentWordContent);
          word.isMarked = await _getWordMarkState(word.word);
          word.isBookmarked = await _getWordBookmarkState(word.word);
          words.add(word);
        } catch (e) {
          print('Error parsing last word content: $currentWordContent');
          print('Error: $e');
        }
      }
      
      return words;
    } catch (e) {
      print('Error loading words: $e');
      throw Exception('Error loading words: $e');
    }
  }

  Future<bool> _getWordMarkState(String word) async {
    final markedWords = _prefs.getStringList(_markedWordsKey) ?? [];
    return markedWords.contains(word);
  }

  Future<bool> _getWordBookmarkState(String word) async {
    final bookmarkedWords = _prefs.getStringList(_bookmarkedWordsKey) ?? [];
    return bookmarkedWords.contains(word);
  }

  Future<void> markWord(String word, bool isMarked) async {
    final markedWords = _prefs.getStringList(_markedWordsKey) ?? [];
    if (isMarked && !markedWords.contains(word)) {
      markedWords.add(word);
    } else if (!isMarked && markedWords.contains(word)) {
      markedWords.remove(word);
    }
    await _prefs.setStringList(_markedWordsKey, markedWords);
  }

  Future<void> bookmarkWord(String word, bool isBookmarked) async {
    final bookmarkedWords = _prefs.getStringList(_bookmarkedWordsKey) ?? [];
    
    // 清除所有现有书签，确保互斥性
    if (isBookmarked) {
      bookmarkedWords.clear(); // 先清除所有书签
      bookmarkedWords.add(word); // 添加新书签
    } else {
      bookmarkedWords.remove(word);
    }
    
    await _prefs.setStringList(_bookmarkedWordsKey, bookmarkedWords);
  }

  Future<void> playAudio(String word) async {
    // TODO: 实现音频播放功能
  }

  // 搜索本地词库
  Future<Word?> searchLocalWord(String word) async {
    try {
      // 先搜索主词库
      final mainWords = await loadWords();
      final mainResult = mainWords.firstWhere(
        (w) => w.word.toLowerCase() == word.toLowerCase(),
        orElse: () => throw 'Not found in main dictionary',
      );
      return mainResult;
    } catch (_) {
      try {
        // 搜索我的单词
        final myWords = await loadMyWords();
        final myResult = myWords.firstWhere(
          (w) => w.word.toLowerCase() == word.toLowerCase(),
          orElse: () => throw 'Not found in my words',
        );
        return myResult;
      } catch (_) {
        return null;
      }
    }
  }

  // 在线搜索单词
  Future<Word?> searchOnlineWord(String word) async {
    try {
      // 获取单词释义和音频URL
      final response = await _dio.get('$_baseUrl/search', queryParameters: {
        'word': word,
        'gender': 'male', // 默认使用男声
      });

      if (response.statusCode != 200 || response.data['code'] != 0) {
        return null;
      }

      final data = response.data['data'];
      final translation = data['translation'];
      final audioUrl = data['audio_url'];

      // 下载男声音频
      final maleResponse = await _dio.get(
        '$_baseUrl/read',
        queryParameters: {
          'word': word,
          'gender': 'male',
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      // 下载女声音频
      final femaleResponse = await _dio.get(
        '$_baseUrl/read',
        queryParameters: {
          'word': word,
          'gender': 'female',
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      // 保存音频文件
      final appDir = await getApplicationDocumentsDirectory();
      
      // 保存男声音频
      final maleAudioFile = File('${appDir.path}/assets/me_words/me_word-man/$word.mp3');
      await maleAudioFile.create(recursive: true);
      await maleAudioFile.writeAsBytes(maleResponse.data);

      // 保存女声音频
      final femaleAudioFile = File('${appDir.path}/assets/me_words/me_word-woman/$word.mp3');
      await femaleAudioFile.create(recursive: true);
      await femaleAudioFile.writeAsBytes(femaleResponse.data);

      // 创建Word对象
      return Word(
        index: 0, // 在线搜索的单词索引为0
        word: word,
        phonetic: '', // API没有提供音标
        partOfSpeech: '', // API没有提供词性
        meaning: translation,
        example: '', // API没有提供例句
        isMarked: false,
        isBookmarked: false,
      );
    } catch (e) {
      print('Error in online search: $e');
      return null;
    }
  }

  // 保存单词到我的单词
  Future<void> saveToMyWords(Word word) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final myWordsFile = File('${appDir.path}/me_words/me_words.md');
      
      // 确保目录存在
      await myWordsFile.parent.create(recursive: true);
      
      // 读取现有内容
      List<String> existingLines = [];
      if (await myWordsFile.exists()) {
        existingLines = await myWordsFile.readAsLines();
      }
      
      // 检查单词是否已存在
      bool wordExists = false;
      for (int i = 0; i < existingLines.length; i++) {
        if (existingLines[i].contains(word.word)) {
          wordExists = true;
          break;
        }
      }
      
      if (!wordExists) {
        // 构建新的单词内容，只包含单词和释义
        final newWordContent = '''${word.word}
${word.meaning}

''';
        
        // 追加新单词
        await myWordsFile.writeAsString(
          newWordContent,
          mode: FileMode.append,
        );
      }
    } catch (e) {
      print('Error saving word to my words: $e');
      rethrow;
    }
  }

  Future<List<Word>> loadMyWords() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final myWordsFile = File('${appDir.path}/me_words/me_words.md');
      
      if (!await myWordsFile.exists()) {
        return [];
      }

      final String content = await myWordsFile.readAsString();
      final List<String> lines = const LineSplitter().convert(content);
      final List<Word> words = [];
      
      String currentWord = '';
      String currentMeaning = '';
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        
        if (line.isEmpty) {
          if (currentWord.isNotEmpty && currentMeaning.isNotEmpty) {
            words.add(Word(
              index: 0,  // 索引不重要，显示时会使用列表索引
              word: currentWord,
              phonetic: '',
              partOfSpeech: '',
              meaning: currentMeaning,
              example: '',
            ));
            currentWord = '';
            currentMeaning = '';
          }
          continue;
        }
        
        if (currentWord.isEmpty) {
          currentWord = line;
        } else if (currentMeaning.isEmpty) {
          currentMeaning = line;
        }
      }
      
      // 处理最后一个单词
      if (currentWord.isNotEmpty && currentMeaning.isNotEmpty) {
        words.add(Word(
          index: 0,
          word: currentWord,
          phonetic: '',
          partOfSpeech: '',
          meaning: currentMeaning,
          example: '',
        ));
      }
      
      return words;
    } catch (e) {
      print('Error loading my words: $e');
      return [];
    }
  }

  Future<bool> downloadAudios(String word) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      
      // 创建音频目录
      final manDir = Directory('${appDir.path}/me_words/me_word-man');
      final womanDir = Directory('${appDir.path}/me_words/me_word-woman');
      await manDir.create(recursive: true);
      await womanDir.create(recursive: true);

      // 下载男声音频
      final maleResponse = await _dio.get(
        'http://ntkednawroii.sealosbja.site/search',
        queryParameters: {'word': word, 'gender': 'male'},
      );
      if (maleResponse.data['code'] == 0) {
        final maleAudioUrl = 'http://ntkednawroii.sealosbja.site${maleResponse.data['data']['audio_url']}';
        final maleAudioResponse = await _dio.get(
          maleAudioUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        final maleAudioFile = File('${manDir.path}/$word.mp3');
        await maleAudioFile.writeAsBytes(maleAudioResponse.data);
      }

      // 下载女声音频
      final femaleResponse = await _dio.get(
        'http://ntkednawroii.sealosbja.site/search',
        queryParameters: {'word': word, 'gender': 'female'},
      );
      if (femaleResponse.data['code'] == 0) {
        final femaleAudioUrl = 'http://ntkednawroii.sealosbja.site${femaleResponse.data['data']['audio_url']}';
        final femaleAudioResponse = await _dio.get(
          femaleAudioUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        final femaleAudioFile = File('${womanDir.path}/$word.mp3');
        await femaleAudioFile.writeAsBytes(femaleAudioResponse.data);
      }

      return true;
    } catch (e) {
      print('Error downloading audios: $e');
      return false;
    }
  }
} 