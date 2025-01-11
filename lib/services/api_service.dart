import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://ntkednawroii.sealosbja.site';
  final Dio _dio = Dio();
  static const String _tokenKey = 'auth_token';

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
      if (phone == '13116346573') {
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
      if (phone == '13116346573' && code == '010101') {
        print('使用测试账号登录');
        // 为测试账号生成一个模拟token
        const testToken = 'test_token_13116346573';
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
      
      if (responseData['code'].toString() != '0') {
        final msg = responseData['msg']?.toString() ?? '退出登录失败';
        print('退出登录失败原因: $msg');
        throw msg;
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
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
} 