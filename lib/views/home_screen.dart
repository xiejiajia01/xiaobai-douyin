import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word.dart';
import '../services/word_service.dart';
import '../services/theme_service.dart';
import '../widgets/word_card.dart';
import '../views/search_screen.dart';
import '../views/my_words_screen.dart';
import '../views/settings_screen.dart';
import '../widgets/flip_animation.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:glass_kit/glass_kit.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with AutomaticKeepAliveClientMixin {
  late WordService _wordService;
  List<Word> _words = [];
  bool _isLoading = true;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  int? _bookmarkedIndex;
  int? _expandedIndex;
  int _lastScrollPosition = 0;
  double _lastLeadingEdge = 0.0;
  bool _showMyWords = false;
  bool _isFlipping = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initWordService();
    _itemPositionsListener.itemPositions.addListener(_saveScrollPosition);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_saveScrollPosition);
    super.dispose();
  }

  void _saveScrollPosition() {
    if (_isFlipping) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      final firstItem = positions.first;
      _lastScrollPosition = firstItem.index;
      _lastLeadingEdge = firstItem.itemLeadingEdge;
    }
  }

  void _restoreScrollPosition() {
    if (_lastScrollPosition > 0 && _itemScrollController.isAttached) {
      _itemScrollController.jumpTo(
        index: _lastScrollPosition,
      );
    }
  }

  Future<void> _initWordService() async {
    try {
      _wordService = await WordService.create();
      await _loadWords();
    } catch (e) {
      print('Error initializing word service: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isReviewMode = await _wordService.getReviewMode();
      final words = isReviewMode 
          ? await _wordService.getMarkedWords()
          : await _wordService.loadWords();
          
      final bookmarkedWord = await _wordService.getCurrentModeBookmarkedWord();
      
      setState(() {
        _words = words;
        _isLoading = false;
        _bookmarkedIndex = bookmarkedWord == null 
            ? null 
            : words.indexWhere((word) => word.word == bookmarkedWord);
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreScrollPosition();
      });
    } catch (e) {
      print('Error loading words: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBookmarked() {
    if (_bookmarkedIndex != null && _itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: _bookmarkedIndex!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }

  void _showSearchScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SearchScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentTheme = ref.watch(themeNotifierProvider);
    
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

    Color getCardColor() {
      switch (currentTheme) {
        case AppThemeMode.dark:
          return Colors.white;
        case AppThemeMode.orange:
          return ThemeColors.orangeCard;
        case AppThemeMode.green:
          return ThemeColors.greenCard;
      }
    }

    final backgroundColor = getBackgroundColor();
    final cardColor = getCardColor();
    final bool isDarkTheme = currentTheme == AppThemeMode.dark;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: FlipAnimation(
        showBackWidget: _showMyWords,
        frontWidget: _buildMainContent(currentTheme, backgroundColor, cardColor, isDarkTheme),
        backWidget: MyWordsScreen(
          onFlipBack: () {
            setState(() {
              _isFlipping = true;
              _showMyWords = false;
            });
          },
        ),
        onFlipComplete: () {
          setState(() {
            _isFlipping = false;
          });
        },
      ),
    );
  }

  Widget _buildMainContent(AppThemeMode currentTheme, Color backgroundColor, Color cardColor, bool isDarkTheme) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          color: backgroundColor,
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: FutureBuilder<bool>(
              future: _wordService.getReviewMode(),
              builder: (context, snapshot) {
                final isReviewMode = snapshot.data ?? false;
                return Text(
                  isReviewMode ? '复习模式' : '小白单词',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? Colors.white : ThemeColors.blackText,
                  ),
                );
              },
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                color: isDarkTheme ? Colors.white : ThemeColors.blackText,
                onPressed: _scrollToBookmarked,
              ),
              IconButton(
                icon: const Icon(Icons.menu),
                color: isDarkTheme ? Colors.white : ThemeColors.blackText,
                onPressed: () async {
                  final settingsChanged = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                  
                  if (settingsChanged == true) {
                    _loadWords();  // 重新加载单词列表
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.primaryDelta!.abs() > 10) {
            _saveScrollPosition();
          }
        },
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity.abs() > 300) {
            if (velocity < 0) {
              setState(() {
                _isFlipping = true;
                _showMyWords = true;
              });
            }
          }
        },
        child: Container(
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
          child: _buildWordList(),
        ),
      ),
      floatingActionButton: GlassContainer(
        height: 56,
        width: 56,
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            isDarkTheme 
                ? Colors.white.withOpacity(0.2)
                : cardColor.withOpacity(0.2),
            isDarkTheme 
                ? Colors.white.withOpacity(0.2)
                : cardColor.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderGradient: LinearGradient(
          colors: [
            isDarkTheme 
                ? Colors.white.withOpacity(0.2)
                : cardColor.withOpacity(0.2),
            isDarkTheme 
                ? Colors.white.withOpacity(0.2)
                : cardColor.withOpacity(0.2),
          ],
        ),
        blur: 20,
        child: IconButton(
          icon: Icon(
            Icons.search, 
            color: isDarkTheme ? Colors.white : ThemeColors.blackText
          ),
          onPressed: _showSearchScreen,
        ),
      ),
    );
  }

  Widget _buildWordList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SafeArea(
      bottom: true,
      child: ScrollablePositionedList.builder(
        itemCount: _words.length,
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        minCacheExtent: 3000,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 100,
          top: 0,
          left: 8,
          right: 8,
        ),
        initialScrollIndex: _lastScrollPosition,
        initialAlignment: _lastLeadingEdge,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: WordCard(
                word: _words[index],
                isExpanded: _expandedIndex == index,
                onExpandChanged: (isExpanded) {
                  setState(() {
                    _expandedIndex = isExpanded ? index : null;
                  });
                },
                onMarkChanged: (isMarked) async {
                  await _wordService.markWord(_words[index].word, isMarked);
                  final isReviewMode = await _wordService.getReviewMode();
                  if (isReviewMode && !isMarked) {
                    setState(() {
                      _words.removeAt(index);
                    });
                  }
                },
                onBookmarkChanged: (isBookmarked) async {
                  if (!isBookmarked) {
                    await _wordService.bookmarkWord(_words[index].word, false);
                    setState(() {
                      _bookmarkedIndex = null;
                    });
                    return;
                  }
                  if (_bookmarkedIndex != null && _bookmarkedIndex != index) {
                    setState(() {
                      _words[_bookmarkedIndex!].isBookmarked = false;
                    });
                  }
                  await _wordService.bookmarkWord(_words[index].word, true);
                  setState(() {
                    _bookmarkedIndex = index;
                    for (int i = 0; i < _words.length; i++) {
                      if (i != index) {
                        _words[i].isBookmarked = false;
                      }
                    }
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
} 