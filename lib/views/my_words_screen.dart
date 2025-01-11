import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word.dart';
import '../services/word_service.dart';
import '../services/theme_service.dart';
import '../widgets/my_word_card.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MyWordsScreen extends ConsumerStatefulWidget {
  final VoidCallback onFlipBack;
  static double lastLeadingEdge = 0;
  static int lastScrollPosition = 0;

  const MyWordsScreen({
    Key? key,
    required this.onFlipBack,
  }) : super(key: key);

  @override
  ConsumerState<MyWordsScreen> createState() => _MyWordsScreenState();
}

class _MyWordsScreenState extends ConsumerState<MyWordsScreen> {
  late WordService _wordService;
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener = ItemPositionsListener.create();
  List<Word> _words = [];
  bool _isLoading = true;
  bool _isFlipping = false;

  @override
  void initState() {
    super.initState();
    _initWordService();
    _positionsListener.itemPositions.addListener(_saveScrollPosition);
  }

  Future<void> _initWordService() async {
    _wordService = await WordService.create();
    _loadWords();
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_saveScrollPosition);
    super.dispose();
  }

  void _saveScrollPosition() {
    final positions = _positionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      MyWordsScreen.lastScrollPosition = positions.first.index;
      MyWordsScreen.lastLeadingEdge = positions.first.itemLeadingEdge;
    }
  }

  Future<void> _loadWords() async {
    final words = await _wordService.loadMyWords();
    if (mounted) {
      setState(() {
        _words = words;
        _isLoading = false;
      });
    }
  }

  Future<void> _showDeleteDialog(Word word) async {
    final currentTheme = ref.watch(themeNotifierProvider);
    final bool isDarkTheme = currentTheme == AppThemeMode.dark;
    
    Color getCardColor() {
      switch (currentTheme) {
        case AppThemeMode.dark:
          return Colors.black;
        case AppThemeMode.orange:
          return ThemeColors.orangeCard;
        case AppThemeMode.green:
          return ThemeColors.greenCard;
      }
    }

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          height: 180,
          width: 300,
          decoration: BoxDecoration(
            color: isDarkTheme 
                ? Colors.black.withOpacity(0.8)
                : getCardColor().withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkTheme 
                  ? Colors.white.withOpacity(0.2)
                  : getCardColor(),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '确定要删除这个单词吗？',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : ThemeColors.blackText,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: isDarkTheme 
                            ? Colors.white.withOpacity(0.1)
                            : getCardColor().withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : ThemeColors.blackText
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final success = await _wordService.deleteMyWord(word.word);
                        if (success && mounted) {
                          Navigator.of(context).pop();
                          _loadWords();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Center(
                                child: Text(
                                  '${word.word} 已删除',
                                  style: TextStyle(
                                    color: isDarkTheme ? Colors.white : ThemeColors.blackText,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              backgroundColor: isDarkTheme 
                                  ? Colors.black87
                                  : getCardColor(),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              margin: EdgeInsets.only(
                                bottom: MediaQuery.of(context).size.height * 0.1,
                                left: 16,
                                right: 16,
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkTheme 
                            ? Colors.red.withOpacity(0.8)
                            : getCardColor(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        '删除',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : ThemeColors.blackText
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeNotifierProvider);
    final bool isDarkTheme = currentTheme == AppThemeMode.dark;
    
    Color getBackgroundColor() {
      switch (currentTheme) {
        case AppThemeMode.dark:
          return Colors.black;
        case AppThemeMode.orange:
          return ThemeColors.orangeBackground;
        case AppThemeMode.green:
          return ThemeColors.greenBackground;
      }
    }

    final backgroundColor = getBackgroundColor();
    
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 300) {
          setState(() {
            _isFlipping = true;
          });
          widget.onFlipBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: backgroundColor,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                '我的单词',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkTheme ? Colors.white : ThemeColors.blackText,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor,
                backgroundColor,
              ],
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _words.isEmpty
                  ? Center(
                      child: Text(
                        '还没有添加单词',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkTheme ? Colors.white : ThemeColors.blackText,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ScrollablePositionedList.builder(
                            itemCount: _words.length,
                            itemScrollController: _scrollController,
                            itemPositionsListener: _positionsListener,
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).padding.bottom + 100,
                              top: 0,
                              left: 8,
                              right: 8,
                            ),
                            initialScrollIndex: MyWordsScreen.lastScrollPosition,
                            initialAlignment: MyWordsScreen.lastLeadingEdge,
                            scrollDirection: Axis.vertical,
                            itemBuilder: (context, index) {
                              return RepaintBoundary(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: GestureDetector(
                                    onLongPress: () => _showDeleteDialog(_words[index]),
                                    child: MyWordCard(
                                      word: _words[index],
                                      displayIndex: index + 1,
                                      themeMode: currentTheme,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
} 