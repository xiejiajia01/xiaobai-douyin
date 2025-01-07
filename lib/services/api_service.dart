import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://your-api-base-url';
  final Dio _dio = Dio();
  static const String _tokenKey = 'auth_token';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
  }

  Future<void> sendVerificationCode(String phone) async {
    try {
      await _dio.post('/send-code', data: {'phone': phone});
    } catch (e) {
      throw '发送验证码失败，请稍后重试';
    }
  }

  Future<String> login(String phone, String code) async {
    try {
      final response = await _dio.post('/login', data: {
        'phone': phone,
        'code': code,
      });

      final token = response.data['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      
      // 设置后续请求的认证头
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      return token;
    } catch (e) {
      throw '登录失败，请检查验证码是否正确';
    }
  }

  Future<String> getWordAudio(String word, {String gender = 'male'}) async {
    try {
      final response = await _dio.get('/read', queryParameters: {
        'word': word,
        'gender': gender,
      });
      
      return response.data['url'] as String;
    } catch (e) {
      throw '获取音频失败';
    }
  }

  Future<Map<String, dynamic>> searchWord(String word) async {
    try {
      final response = await _dio.get('/search', queryParameters: {
        'word': word,
      });
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw '搜索单词失败';
    }
  }
} 