import 'package:flutter/material.dart';
import '../models/word.dart';
import '../widgets/word_card.dart';
import '../services/word_service.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late WordService _wordService;
  Word? _searchResult;
  bool _isSearching = false;
  bool _showOnlineSearchPrompt = false;
  bool _isOnlineSearchResult = false;

  @override
  void initState() {
    super.initState();
    _initWordService();
  }

  Future<void> _initWordService() async {
    try {
      _wordService = await WordService.create();
    } catch (e) {
      print('Error initializing word service: $e');
      _showErrorDialog('初始化失败，请重试');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchWord(String word) async {
    if (word.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResult = null;
      _showOnlineSearchPrompt = false;
      _isOnlineSearchResult = false;
    });

    try {
      // 先搜索本地词库
      final localWord = await _wordService.searchLocalWord(word);
      
      if (localWord != null) {
        setState(() {
          _searchResult = localWord;
          _isSearching = false;
          _isOnlineSearchResult = false;
        });
        return;
      }

      // 如果本地没有找到，显示在线搜索提示
      setState(() {
        _isSearching = false;
        _showOnlineSearchPrompt = true;
      });
    } catch (e) {
      print('Error searching word: $e');
      setState(() {
        _isSearching = false;
      });
      _showErrorDialog('搜索出错，请稍后重试');
    }
  }

  Future<void> _performOnlineSearch() async {
    setState(() {
      _isSearching = true;
      _showOnlineSearchPrompt = false;
    });

    try {
      final onlineWord = await _wordService.searchOnlineWord(_searchController.text);
      
      if (onlineWord != null) {
        setState(() {
          _searchResult = onlineWord;
          _isOnlineSearchResult = true;
        });
      } else {
        _showErrorDialog('未找到该单词');
      }
    } catch (e) {
      print('Error searching online: $e');
      _showErrorDialog('在线搜索失败，请检查网络连接');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(message),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSavePrompt() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.save_outlined, color: Colors.blue, size: 48),
              const SizedBox(height: 16),
              const Text('是否将该单词加入到"我的单词"？'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _wordService.saveToMyWords(_searchResult!);
                      _showSuccessDialog('单词已添加到"我的单词"');
                    },
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
              const SizedBox(height: 16),
              Text(message),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAutoHideSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // 1秒后自动关闭对话框
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pop();
        });

        return Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            child: Text(
              '单词已添加到"我的单词"',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: GlassContainer(
              height: 48,
              width: double.infinity,
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              borderGradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.1),
                ],
              ),
              blur: 20,
              child: Center(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.black),
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    hintText: '搜索单词...',
                    hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search, color: Colors.black.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    isDense: true,
                  ),
                  onSubmitted: _searchWord,
                ),
              ),
            ),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_showOnlineSearchPrompt) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '未找到该单词',
              style: TextStyle(color: Colors.black.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performOnlineSearch,
              child: const Text('在线搜索'),
            ),
          ],
        ),
      );
    }

    if (_searchResult != null) {
      return SingleChildScrollView(
        child: Column(
          children: [
            SearchWordCard(
              word: _searchResult!,
              isOnlineWord: _isOnlineSearchResult,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    '取消',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 32),
                ElevatedButton(
                  onPressed: () async {
                    await _wordService.saveToMyWords(_searchResult!);
                    Navigator.of(context).pop();
                    _showAutoHideSuccessDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    '加入我的单词',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    return Center(
      child: Text(
        '输入单词开始搜索',
        style: TextStyle(color: Colors.black.withOpacity(0.5)),
      ),
    );
  }
}

class SearchWordCard extends StatefulWidget {
  final Word word;
  final bool isOnlineWord;

  const SearchWordCard({
    Key? key,
    required this.word,
    this.isOnlineWord = false,
  }) : super(key: key);

  @override
  _SearchWordCardState createState() => _SearchWordCardState();
}

class _SearchWordCardState extends State<SearchWordCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isDownloading = false;
  bool _hasDownloaded = false;
  late WordService _wordService;

  @override
  void initState() {
    super.initState();
    _initWordService();
  }

  Future<void> _initWordService() async {
    _wordService = await WordService.create();
    if (widget.isOnlineWord) {
      _downloadAudios();
    }
  }

  Future<void> _downloadAudios() async {
    setState(() {
      _isDownloading = true;
    });

    final success = await _wordService.downloadAudios(widget.word.word);
    
    setState(() {
      _isDownloading = false;
      _hasDownloaded = success;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (_isPlaying || _isDownloading) return;

    setState(() {
      _isPlaying = true;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final audioPath = widget.isOnlineWord
          ? '${appDir.path}/me_words/me_word-man/${widget.word.word}.mp3'
          : 'assets/words/word-man/${widget.word.word}.mp3';
      
      if (widget.isOnlineWord) {
        // 在线单词使用 setFilePath
        await _audioPlayer.setFilePath(audioPath);
      } else {
        // 本地单词使用 setAsset
        await _audioPlayer.setAsset(audioPath);
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
            Colors.black.withOpacity(0.1),
            Colors.black.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        borderGradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.2),
            Colors.black.withOpacity(0.1),
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
                    '${widget.word.index + 1}.',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.word.word,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isDownloading ? Icons.downloading : 
                      _isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
                      color: (_isDownloading || (widget.isOnlineWord && !_hasDownloaded)) 
                          ? Colors.black26  // 禁用状态颜色
                          : Colors.black54,
                    ),
                    onPressed: (_isDownloading || (widget.isOnlineWord && !_hasDownloaded)) 
                        ? null  // 下载中或未下载时禁用
                        : _playAudio,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.word.meaning,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 