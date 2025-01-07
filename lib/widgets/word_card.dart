import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:path_provider/path_provider.dart';
import '../models/word.dart';
import '../services/word_service.dart';

class WordCard extends StatefulWidget {
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
  _WordCardState createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
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
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          borderGradient: LinearGradient(
            colors: [
              widget.word.isMarked 
                  ? const Color(0xFFEEE7CE)
                  : Colors.white.withOpacity(0.2),
              widget.word.isMarked 
                  ? const Color(0xFFEEE7CE)
                  : Colors.white.withOpacity(0.1),
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
                const SizedBox(height: 0),
                Row(
                  children: [
                    Text(
                      '[${widget.word.phonetic}] ${widget.word.partOfSpeech}.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    if (widget.showMarkButton) IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        widget.word.isMarked ? Icons.check_circle : Icons.check_circle_outline,
                        color: widget.word.isMarked ? Colors.green : Colors.white70,
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
                          color: widget.word.isBookmarked ? const Color(0xFFFFA000) : Colors.white70,
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
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.word.example.isNotEmpty) ...[
                    const SizedBox(height: 0),
                    Text(
                      widget.word.example,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
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