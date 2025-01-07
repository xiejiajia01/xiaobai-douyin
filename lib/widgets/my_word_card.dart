import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:path_provider/path_provider.dart';
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
    });

    try {
      // 检查应用文档目录中是否存在音频文件
      final appDir = await getApplicationDocumentsDirectory();
      final meWordPath = '${appDir.path}/me_words/me_word-man/${widget.word.word}.mp3';
      final meWordFile = File(meWordPath);
      
      if (await meWordFile.exists()) {
        // 如果在应用文档目录中找到音频文件，使用 setFilePath
        await _audioPlayer.setFilePath(meWordPath);
      } else {
        // 如果没有找到，则使用 assets 目录中的音频文件
        await _audioPlayer.setAsset('assets/words/word-man/${widget.word.word}.mp3');
      }
      
      await _audioPlayer.play();
      
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    } catch (e) {
      print('Error playing audio: $e');
      setState(() {
        _isPlaying = false;
      });
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