import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/word.dart';
import '../services/word_service.dart';
import '../widgets/word_card.dart';
import '../views/search_screen.dart';
import '../views/my_words_screen.dart';
import '../views/settings_screen.dart';
import '../widgets/flip_animation.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:glass_kit/glass_kit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
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
      print('保存位置: index=$_lastScrollPosition, offset=$_lastLeadingEdge');
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
      await _wordService.initialize();
      final words = await _wordService.loadWords();
      setState(() {
        _words = words;
        _isLoading = false;
      });
      
      // 恢复滚动位置
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
        alignment: 0.3, // 将书签卡片位置调整到屏幕上方30%处
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: FlipAnimation(
        showBackWidget: _showMyWords,
        frontWidget: _buildMainContent(),
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

  Widget _buildMainContent() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          color: Colors.black,  // 确保背景色与页面一致
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              '小白单词',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                color: Colors.white,
                onPressed: _scrollToBookmarked,
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                color: Colors.white,
                onPressed: () async {
                  final settingsChanged = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                  
                  // 只有当设置真正改变时才重新加载
                  if (settingsChanged == true) {
                    // 强制重建所有 WordCard
                    setState(() {
                      _words = List.from(_words);
                    });
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
            if (velocity < 0) {  // 左滑
              setState(() {
                _isFlipping = true;
                _showMyWords = true;
              });
            }
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.black, Colors.black],
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
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        blur: 20,
        child: IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
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