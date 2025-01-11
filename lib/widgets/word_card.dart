import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';
import '../services/word_service.dart';
import '../services/theme_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WordCard extends ConsumerStatefulWidget {
  final Word word;
  final bool isExpanded;
  final ValueChanged<bool> onExpandChanged;
  final ValueChanged<bool> onMarkChanged;
  final ValueChanged<bool> onBookmarkChanged;
  final bool showMarkButton;
  final bool showBookmarkButton;

  const WordCard({
    Key? key,
    required this.word,
    required this.isExpanded,
    required this.onExpandChanged,
    required this.onMarkChanged,
    required this.onBookmarkChanged,
    this.showMarkButton = true,
    this.showBookmarkButton = true,
  }) : super(key: key);

  @override
  ConsumerState<WordCard> createState() => _WordCardState();
}

class _WordCardState extends ConsumerState<WordCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isWomanVoice = false;

  @override
  void initState() {
    super.initState();
    _loadVoiceSettings();
  }

  @override
  void didUpdateWidget(WordCard oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeNotifierProvider);
    
    Color getCardBackgroundColor() {
      switch (currentTheme) {
        case AppThemeMode.dark:
          return Colors.transparent;
        case AppThemeMode.orange:
          return widget.word.isMarked ? ThemeColors.orangeCard : ThemeColors.orangeDefaultCard;
        case AppThemeMode.green:
          return widget.word.isMarked ? ThemeColors.greenCard : ThemeColors.greenDefaultCard;
      }
    }

    final Color cardBackgroundColor = getCardBackgroundColor();
    final bool isDarkTheme = currentTheme == AppThemeMode.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          widget.onExpandChanged(!widget.isExpanded);
        },
        child: GlassContainer(
          height: widget.isExpanded ? 160.0 : 120.0,
          width: double.infinity,
          gradient: LinearGradient(
            colors: [
              cardBackgroundColor,
              cardBackgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          borderGradient: LinearGradient(
            colors: [
              isDarkTheme 
                  ? (widget.word.isMarked 
                      ? const Color(0xFFFFC107)
                      : const Color(0xFFEEE7CE))
                  : const Color(0xFFEEE7CE),
              isDarkTheme 
                  ? (widget.word.isMarked 
                      ? const Color(0xFFFFC107)
                      : const Color(0xFFEEE7CE))
                  : const Color(0xFFEEE7CE),
            ],
          ),
          blur: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '${widget.word.index}.',
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
                const SizedBox(height: 0),
                Row(
                  children: [
                    Text(
                      '[${widget.word.phonetic}] ${widget.word.partOfSpeech}.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkTheme ? Colors.white70 : ThemeColors.blackText,
                      ),
                    ),
                    const Spacer(),
                    if (widget.showMarkButton) IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        widget.word.isMarked ? Icons.check_circle : Icons.check_circle_outline,
                        color: widget.word.isMarked 
                            ? (currentTheme == AppThemeMode.dark 
                                ? const Color(0xFF006FFF)
                                : currentTheme == AppThemeMode.orange
                                    ? const Color(0xFFC2402A)
                                    : const Color(0xFFFFFFa1))
                            : (isDarkTheme ? Colors.white70 : ThemeColors.blackText),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          widget.word.isMarked = !widget.word.isMarked;
                        });
                        widget.onMarkChanged(widget.word.isMarked);
                      },
                    ),
                    if (widget.showBookmarkButton) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          widget.word.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: widget.word.isBookmarked 
                              ? (currentTheme == AppThemeMode.dark 
                                  ? const Color(0xFF006FFF)
                                  : currentTheme == AppThemeMode.orange
                                      ? const Color(0xFFC2402A)
                                      : const Color(0xFFFFFFa1))
                              : (isDarkTheme ? Colors.white70 : ThemeColors.blackText),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            widget.word.isBookmarked = !widget.word.isBookmarked;
                          });
                          widget.onBookmarkChanged(widget.word.isBookmarked);
                        },
                      ),
                    ],
                  ],
                ),
                if (widget.isExpanded) ...[
                  const SizedBox(height: 0),
                  Text(
                    widget.word.meaning,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkTheme ? Colors.white : ThemeColors.blackText,
                    ),
                  ),
                  if (widget.word.example.isNotEmpty) ...[
                    const SizedBox(height: 0),
                    Text(
                      widget.word.example,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkTheme ? Colors.white70 : ThemeColors.blackText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
} 