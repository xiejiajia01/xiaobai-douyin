import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';

class MyWordCard extends StatefulWidget {
  final Word word;
  final int displayIndex;

  const MyWordCard({
    Key? key,
    required this.word,
    required this.displayIndex,
  }) : super(key: key);

  @override
  _MyWordCardState createState() => _MyWordCardState();
}

class _MyWordCardState extends State<MyWordCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isWomanVoice = false;

  @override
  void initState() {
    super.initState();
    _loadVoiceSettings();
  }

  @override
  void didUpdateWidget(MyWordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadVoiceSettings();
  }

  Future<void> _loadVoiceSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newVoiceSetting = prefs.getBool('isWomanVoice') ?? false;
      if (mounted && newVoiceSetting != _isWomanVoice) {
        setState(() {
          _isWomanVoice = newVoiceSetting;
        });
      }
    } catch (e) {
      print('Error loading voice settings: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (_isPlaying) return;

    // 每次播放前重新加载设置
    await _loadVoiceSettings();

    setState(() {
      _isPlaying = true;
    });

    try {
      // 检查应用文档目录中是否存在音频文件
      final appDir = await getApplicationDocumentsDirectory();
      final voiceType = _isWomanVoice ? 'woman' : 'man';
      final meWordPath = '${appDir.path}/me_words/me_word-$voiceType/${widget.word.word}.mp3';
      final meWordFile = File(meWordPath);
      
      print('当前音色设置: ${_isWomanVoice ? "女声" : "男声"}');
      print('尝试播放本地文件路径: $meWordPath');
      print('本地文件是否存在: ${await meWordFile.exists()}');
      
      if (await meWordFile.exists()) {
        // 如果在应用文档目录中找到音频文件，使用 setFilePath
        print('使用本地文件播放');
        await _audioPlayer.setFilePath(meWordPath);
      } else {
        // 如果没有找到，则使用 assets 目录中的音频文件
        final assetPath = 'assets/words/word-$voiceType/${widget.word.word}.mp3';
        print('使用assets文件播放: $assetPath');
        await _audioPlayer.setAsset(assetPath);
      }
      
      await _audioPlayer.play();
      
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
          }
        }
      });
    } catch (e) {
      print('Error playing audio: $e');
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassContainer(
        height: 120,
        width: double.infinity,
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        blur: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${widget.displayIndex}.',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.word.word,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
                      color: Colors.white70,
                    ),
                    onPressed: _playAudio,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.word.meaning,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 