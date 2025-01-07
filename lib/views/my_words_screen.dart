import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/word_service.dart';
import '../widgets/my_word_card.dart';
import '../widgets/flip_page_route.dart';
import '../views/home_screen.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MyWordsScreen extends StatefulWidget {
  final VoidCallback onFlipBack;
  static int lastScrollPosition = 0;
  static double lastLeadingEdge = 0.0;

  const MyWordsScreen({
    Key? key,
    required this.onFlipBack,
  }) : super(key: key);

  @override
  _MyWordsScreenState createState() => _MyWordsScreenState();
}

class _MyWordsScreenState extends State<MyWordsScreen> {
  late WordService _wordService;
  List<Word> _words = [];
  bool _isLoading = true;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  bool _isFlipping = false;

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
      MyWordsScreen.lastScrollPosition = firstItem.index;
      MyWordsScreen.lastLeadingEdge = firstItem.itemLeadingEdge;
      print('保存位置(我的单词): index=${MyWordsScreen.lastScrollPosition}, offset=${MyWordsScreen.lastLeadingEdge}');
    }
  }

  void _restoreScrollPosition() {
    if (MyWordsScreen.lastScrollPosition > 0 && _itemScrollController.isAttached) {
      _itemScrollController.jumpTo(
        index: MyWordsScreen.lastScrollPosition,
        alignment: MyWordsScreen.lastLeadingEdge,
      );
    }
  }

  Future<void> _initWordService() async {
    if (!mounted) return;
    try {
      _wordService = await WordService.create();
      if (!mounted) return;
      await _loadWords();
    } catch (e) {
      print('Error initializing word service: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWords() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final words = await _wordService.loadMyWords();
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 300) {  // 右滑返回
          setState(() {
            _isFlipping = true;
          });
          widget.onFlipBack();
        }
      },
      child: Scaffold(
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
                '我的单词',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black,
                Colors.black,
              ],
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _words.isEmpty
                  ? Center(
                      child: Text(
                        '空',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
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
                            initialScrollIndex: MyWordsScreen.lastScrollPosition,
                            initialAlignment: MyWordsScreen.lastLeadingEdge,
                            scrollDirection: Axis.vertical,
                            itemBuilder: (context, index) {
                              return RepaintBoundary(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: MyWordCard(
                                    word: _words[index],
                                    displayIndex: index + 1,
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