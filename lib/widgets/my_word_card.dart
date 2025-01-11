import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';
import '../services/theme_service.dart';

class MyWordCard extends StatefulWidget {
  final Word word;
  final int displayIndex;
  final AppThemeMode themeMode;

  const MyWordCard({
    Key? key,
    required this.word,
    required this.displayIndex,
    required this.themeMode,
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
    await _loadVoiceSettings();
    setState(() {
      _isPlaying = true;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final voiceType = _isWomanVoice ? 'woman' : 'man';
      final meWordPath = '${appDir.path}/me_words/me_word-$voiceType/${widget.word.word}.mp3';
      final meWordFile = File(meWordPath);
      
      if (await meWordFile.exists()) {
        await _audioPlayer.setFilePath(meWordPath);
      } else {
        final assetPath = 'assets/words/word-$voiceType/${widget.word.word}.mp3';
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

  Color _getCardColor() {
    switch (widget.themeMode) {
      case AppThemeMode.dark:
        return Colors.transparent;
      case AppThemeMode.orange:
        return ThemeColors.orangeCard;
      case AppThemeMode.green:
        return ThemeColors.greenCard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = widget.themeMode == AppThemeMode.dark;
    final cardColor = _getCardColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassContainer(
        height: 120,
        width: double.infinity,
        gradient: LinearGradient(
          colors: [
            isDarkTheme 
                ? cardColor
                : cardColor,
            isDarkTheme 
                ? cardColor
                : cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        borderGradient: LinearGradient(
          colors: [
            isDarkTheme 
                ? const Color(0xFFEEE7CE)
                : cardColor,
            isDarkTheme 
                ? const Color(0xFFEEE7CE)
                : cardColor,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkTheme ? Colors.white : ThemeColors.blackText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.word.word,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkTheme ? Colors.white : ThemeColors.blackText,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
                      color: isDarkTheme ? Colors.white70 : ThemeColors.blackText,
                    ),
                    onPressed: _playAudio,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.word.meaning,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkTheme ? Colors.white : ThemeColors.blackText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 