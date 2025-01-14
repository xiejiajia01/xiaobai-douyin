import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  static const String baseUrl = 'https://test.lazijil.cc';
  final Dio _dio = Dio();
  static const String _tokenKey = 'auth_token';
  static const String _dailySentenceKey = 'daily_sentence';
  static const String _lastFetchTimeKey = 'last_fetch_time';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
    _dio.options.headers = {
      'Content-Type': 'application/json',
    };
    _initializeToken();
  }

  Future<void> _initializeToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    try {
      print('开始处理响应数据: ${response.data}');
      print('响应数据类型: ${response.data.runtimeType}');
      
      // 如果响应数据是字符串，尝试解析为JSON
      if (response.data is String) {
        try {
          return Map<String, dynamic>.from(json.decode(response.data));
        } catch (e) {
          print('JSON解析失败: $e');
          throw '服务器响应格式错误';
        }
      }
      
      // 如果响应数据已经是Map类型
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      
      print('响应数据类型错误: ${response.data.runtimeType}');
      throw '服务器响应格式错误';
    } catch (e) {
      print('响应处理错误: $e');
      throw '服务器响应格式错误';
    }
  }

  Future<void> sendVerificationCode(String phone) async {
    try {
      print('API请求开始 - 发送验证码到: $phone');
      
      // 测试账号逻辑
      if (phone == '13100000000') {
        print('测试账号，跳过发送验证码');
        return;
      }
      
      // 正常发送验证码流程
      final response = await _dio.post('/send-code', 
        data: {'phone': phone}
      );
      print('原始API响应: ${response.data}');
      print('响应状态码: ${response.statusCode}');
      print('响应头: ${response.headers}');
      
      // 如果状态码是200，且响应数据包含成功标识，则认为发送成功
      if (response.statusCode == 200) {
        final responseData = _handleResponse(response);
        print('处理后的响应数据: $responseData');
        
        final code = responseData['code'];
        print('响应code: $code (类型: ${code.runtimeType})');
        
        if (code.toString() != '0') {
          final msg = responseData['msg']?.toString() ?? '发送验证码失败';
          print('API返回错误: $msg');
          throw msg;
        }
        print('验证码发送成功');
        return;
      }
      
      throw '发送验证码失败: 服务器响应异常';
    } catch (e) {
      print('API异常: $e');
      if (e is DioException) {
        print('网络错误详情: ${e.message}');
        print('错误类型: ${e.type}');
        print('错误响应: ${e.response?.data}');
        
        // 处理特定的错误响应
        if (e.response?.data == 'Failed to send SMS') {
          throw '发送次数过多，请稍后再试';
        }
        
        throw '网络错误，请稍后重试';
      }
      rethrow;
    }
  }

  Future<void> login(String phone, String code) async {
    try {
      print('登录请求开始 - 手机号: $phone, 验证码: $code');
      
      // 测试账号逻辑
      if (phone == '13100000000' && code == '010101') {
        print('使用测试账号登录');
        // 为测试账号生成一个模拟token
        const testToken = 'test_token_13100000000';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, testToken);
        _dio.options.headers['Authorization'] = 'Bearer $testToken';
        print('测试账号登录成功');
        return;
      }
      
      // 正常登录流程
      final response = await _dio.post('/login', 
        data: {
          'phone': phone,
          'code': code,
        }
      );
      print('原始登录响应: ${response.data}');
      print('响应状态码: ${response.statusCode}');
      print('响应头: ${response.headers}');
      
      final responseData = _handleResponse(response);
      print('处理后的登录响应数据: $responseData');
      
      final responseCode = responseData['code'];
      print('登录响应code: $responseCode (类型: ${responseCode.runtimeType})');
      
      if (responseCode.toString() != '0') {
        final msg = responseData['msg']?.toString() ?? '登录失败';
        print('登录失败原因: $msg');
        throw msg;
      }

      final data = responseData['data'];
      print('登录数据: $data (类型: ${data.runtimeType})');
      
      if (data is! Map<String, dynamic>) {
        print('登录数据格式错误: 期望Map<String, dynamic>，实际是${data.runtimeType}');
        throw '登录数据格式错误';
      }

      final token = data['token']?.toString();
      print('获取到的token: ${token?.substring(0, 10)}... (长度: ${token?.length})');
      
      if (token == null || token.isEmpty) {
        print('token无效: ${token == null ? "null" : "空字符串"}');
        throw '登录token无效';
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      
      _dio.options.headers['Authorization'] = 'Bearer $token';
      print('登录成功，token已保存到本地存储和请求头');
    } catch (e) {
      print('登录失败: $e');
      if (e is DioException) {
        print('网络错误详情: ${e.message}');
        print('错误类型: ${e.type}');
        print('错误响应: ${e.response?.data}');
        throw '网络错误，请稍后重试';
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      print('开始退出登录');
      final response = await _dio.post('/logout');
      print('退出登录响应: ${response.data}');
      
      final responseData = _handleResponse(response);
      print('处理后的退出登录响应: $responseData');
      
      final responseCode = responseData['code']?.toString() ?? '';
      if (responseCode != '0') {
        final msg = responseData['msg']?.toString() ?? '退出登录失败';
        print('退出登录失败原因: $msg');
        throw msg;
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      _dio.options.headers.remove('Authorization');
      print('退出登录成功，已清除本地token');
    } catch (e) {
      print('退出登录失败: $e');
      if (e is DioException) {
        print('网络错误详情: ${e.message}');
        print('错误类型: ${e.type}');
        print('错误响应: ${e.response?.data}');
        throw '网络错误，请稍后重试';
      }
      rethrow;
    }
  }

  Future<String> getWordAudio(String word, {String gender = 'male'}) async {
    try {
      final response = await _dio.get('/read', 
        queryParameters: {
          'word': word,
          'gender': gender,
        }
      );
      
      if (response.statusCode == 302) {
        return response.headers.value('location') ?? '';
      }
      
      throw '获取音频失败';
    } catch (e) {
      if (e is DioException) {
        throw '网络错误，请稍后重试';
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> searchWord(String word) async {
    try {
      final response = await _dio.get('/search', 
        queryParameters: {
          'word': word,
        }
      );
      
      if (response.data['code'] != 0) {
        throw response.data['msg'];
      }
      
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        throw '网络错误，请稍后重试';
      }
      rethrow;
    }
  }

  Future<Map<String, String>> getDailySentence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchTime = prefs.getInt(_lastFetchTimeKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // 检查是否需要重新获取（8小时 = 8 * 60 * 60 * 1000 毫秒）
      if (currentTime - lastFetchTime >= 8 * 60 * 60 * 1000) {
        print('获取新的每日佳句');
        final response = await _dio.get('https://api.kekc.cn/api/yien');
        
        if (response.statusCode == 200 && response.data != null) {
          final sentence = {
            'en': (response.data['en'] ?? '').toString(),
            'cn': (response.data['cn'] ?? '').toString(),
          };
          
          // 保存新句子和获取时间
          await prefs.setString(_dailySentenceKey, json.encode(sentence));
          await prefs.setInt(_lastFetchTimeKey, currentTime);
          
          return sentence;
        }
      }
      
      // 返回缓存的句子
      final cachedSentence = prefs.getString(_dailySentenceKey);
      if (cachedSentence != null) {
        final Map<String, dynamic> decoded = json.decode(cachedSentence);
        return {
          'en': (decoded['en'] ?? '').toString(),
          'cn': (decoded['cn'] ?? '').toString(),
        };
      }
      
      // 如果没有缓存，返回默认值
      return {
        'en': 'Life is short, keep learning.',
        'cn': '生命短暂，持续学习。',
      };
      
    } catch (e) {
      print('获取每日佳句失败: $e');
      return {
        'en': 'Life is short, keep learning.',
        'cn': '生命短暂，持续学习。',
      };
    }
  }

  Future<String> generateAIWriting(List<String> words) async {
    try {
      print('开始生成AI写作内容，使用${words.length}个单词');
      final response = await _dio.post(
        '/write',
        data: {
          'words': words,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      
      if (response.data['code'] != 0) {
        throw response.data['msg'] ?? '生成失败';
      }
      
      return response.data['data']['content'] as String;
    } catch (e) {
      print('AI写作生成失败: $e');
      if (e is DioException) {
        if (e.type == DioExceptionType.receiveTimeout) {
          throw 'AI生成超时，请稍后重试';
        }
        throw '网络错误，请稍后重试';
      }
      rethrow;
    }
  }

  static const int _maxCacheAge = 7 * 24 * 60 * 60 * 1000; // 7天
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB

  Future<void> cleanSentenceAudioCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final sentenceAudioDir = Directory('${appDir.path}/sentence_audio');
      if (!await sentenceAudioDir.exists()) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      int totalSize = 0;
      List<FileSystemEntity> files = await sentenceAudioDir.list().toList();
      
      // 按修改时间排序
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      for (var file in files) {
        if (file is File) {
          final stat = file.statSync();
          final age = now - stat.modified.millisecondsSinceEpoch;
          final size = stat.size;

          // 删除过期文件或当缓存总大小超过限制时删除最旧的文件
          if (age > _maxCacheAge || totalSize + size > _maxCacheSize) {
            await file.delete();
          } else {
            totalSize += size;
          }
        }
      }
    } catch (e) {
      print('清理音频缓存失败: $e');
    }
  }

  String _getSentenceFileName(String sentence, String gender) {
    final hash = md5.convert(utf8.encode(sentence)).toString();
    return '$hash-$gender.mp3';
  }

  Future<String> getSentenceAudioPath(String sentence, String gender) async {
    // 先清理缓存
    await cleanSentenceAudioCache();
    
    final appDir = await getApplicationDocumentsDirectory();
    final sentenceAudioDir = Directory('${appDir.path}/sentence_audio');
    await sentenceAudioDir.create(recursive: true);

    final fileName = _getSentenceFileName(sentence, gender);
    final file = File('${sentenceAudioDir.path}/$fileName');

    // 如果文件存在且未过期，直接返回
    if (await file.exists()) {
      final age = DateTime.now().millisecondsSinceEpoch - 
                  file.statSync().modified.millisecondsSinceEpoch;
      if (age < _maxCacheAge) {
        return file.path;
      }
      // 如果文件过期，删除它
      await file.delete();
    }

    // 下载新文件
    final response = await _dio.get(
      '/read',
      queryParameters: {
        'word': sentence,
        'gender': gender,
      },
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (status) => status! < 500,
        // 针对音频文件增加超时时间
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
    );

    if (response.statusCode == 200) {
      await file.writeAsBytes(response.data);
      return file.path;
    }

    throw '获取音频失败';
  }
} 