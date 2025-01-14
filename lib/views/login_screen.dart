import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _canSendCode = true;
  bool _agreedToTerms = false;
  int _countdown = 60;
  Timer? _timer;
  final _apiService = ApiService();

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFFF5F5F0).withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 120,
          right: 40,
          left: 40,
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _startCountdown() {
    setState(() {
      _canSendCode = false;
      _countdown = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _canSendCode = true;
          timer.cancel();
        }
      });
    });
  }

  Future<String> _loadAgreement(String filename) async {
    try {
      return await rootBundle.loadString('$filename.txt');
    } catch (e) {
      print('Error loading agreement: $e');
      return '加载协议内容失败';
    }
  }

  void _showAgreement(String title, String type) async {
    String content = await _loadAgreement(type);
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SelectableText.rich(
            TextSpan(
              text: content,
              style: const TextStyle(fontSize: 14),
              children: _buildClickableLinks(content),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildClickableLinks(String text) {
    final List<TextSpan> spans = [];
    final RegExp exp = RegExp(r'《(.*?)》');
    int lastIndex = 0;

    for (final Match match in exp.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      final String linkText = match.group(1)!;
      spans.add(
        TextSpan(
          text: '《$linkText》',
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              String type = '';
              switch (linkText) {
                case '用户协议':
                  type = 'xieyi';
                  break;
                case '隐私政策':
                  type = 'yinsi';
                  break;
                case '儿童隐私政策':
                  type = 'ertong';
                  break;
              }
              if (type.isNotEmpty) {
                _showAgreement(linkText, type);
              }
            },
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }

  Future<void> _sendVerificationCode() async {
    if (!_agreedToTerms) {
      _showSnackBar('请先同意用户协议和隐私政策');
      return;
    }
    
    if (!mounted) return;
    
    final phone = _phoneController.text.trim();
    print('发送验证码 - 手机号: $phone');
    
    if (phone.isEmpty || phone.length != 11) {
      print('手机号格式错误');
      _showSnackBar('请输入正确的手机号');
      return;
    }

    try {
      print('开始调用发送验证码API');
      await _apiService.sendVerificationCode(phone);
      print('发送验证码API调用成功，开始倒计时');
      
      if (!mounted) return;

      _startCountdown();
      print('倒计时开始: $_countdown');
    } catch (e) {
      print('发送验证码失败: $e');
      if (!mounted) return;
      
      if (e.toString().contains('服务器响应格式错误')) {
        print('服务器响应格式错误，但验证码可能已发送成功，启动倒计时');
        _startCountdown();
      } else {
        _showSnackBar(e.toString());
      }
    }
  }

  Future<void> _login() async {
    if (!mounted) return;
    
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    print('尝试登录 - 手机号: $phone, 验证码: $code');

    if (phone.isEmpty || phone.length != 11) {
      _showSnackBar('请输入正确的手机号');
      return;
    }

    if (code.isEmpty || code.length != 6) {
      _showSnackBar('请输入6位验证码');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('开始登录');
      await _apiService.login(phone, code);
      print('登录成功，准备跳转');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      print('登录失败: $e');
      if (!mounted) return;
      _showSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(  // 添加滚动支持
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 80),  // 添加顶部间距
                const Text(
                  '小白单词',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: '手机号',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: '验证码',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        onPressed: _canSendCode && _agreedToTerms ? _sendVerificationCode : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.white24,
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _canSendCode ? '发送验证码' : '${_countdown}s',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreedToTerms = value ?? false;
                        });
                      },
                      fillColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.selected)) {
                            return Colors.white;
                          }
                          return Colors.white70;
                        },
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreedToTerms = !_agreedToTerms;
                          });
                        },
                        child: SelectableText.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: '登录即代表您同意',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              TextSpan(
                                text: '《用户协议》',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _showAgreement('用户协议', 'xieyi'),
                              ),
                              const TextSpan(
                                text: '、',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              TextSpan(
                                text: '《隐私政策》',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _showAgreement('隐私政策', 'yinsi'),
                              ),
                              const TextSpan(
                                text: '和',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              TextSpan(
                                text: '《儿童隐私政策》',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _showAgreement('儿童隐私政策', 'ertong'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white24,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading) ...[
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black38),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Text(
                        '登录',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
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
  }
} 