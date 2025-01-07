import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../models/word.dart';
import '../widgets/word_card.dart';
import '../widgets/my_word_card.dart';

class FlipPageRoute extends PageRouteBuilder {
  final Widget child;
  final bool reverse;
  final List<Word> words;
  final int currentIndex;
  final int? expandedIndex;
  final ItemScrollController scrollController;
  final double initialAlignment;
  final Function(bool) onExpandChanged;
  final Function(bool) onMarkChanged;
  final Function(bool) onBookmarkChanged;

  static final GlobalKey<State<StatefulWidget>> _listKey = GlobalKey();

  FlipPageRoute({
    required this.child,
    required this.words,
    required this.currentIndex,
    required this.expandedIndex,
    required this.scrollController,
    required this.onExpandChanged,
    required this.onMarkChanged,
    required this.onBookmarkChanged,
    required this.initialAlignment,
    this.reverse = false,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 800),
          reverseTransitionDuration: const Duration(milliseconds: 800),
          opaque: false,
          barrierDismissible: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                // 前90度（当前页面）
                AnimatedBuilder(
                  animation: curvedAnimation,
                  builder: (context, _) {
                    final value = curvedAnimation.value;
                    final angle = value * math.pi;
                    
                    if (value >= 0.5) return const SizedBox.shrink();

                    return Opacity(
                      opacity: 1 - value * 2,
                      child: Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.002)
                          ..rotateY(reverse ? angle : -angle),
                        alignment: Alignment.center,
                        child: AbsorbPointer(
                          absorbing: value > 0.0,
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                            child: Scaffold(
                              key: _listKey,
                              backgroundColor: Colors.transparent,
                              appBar: AppBar(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                automaticallyImplyLeading: false,
                                title: Text(
                                  reverse ? '我的单词' : '小白单词',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                centerTitle: reverse,
                                actions: reverse ? [] : [
                                  IconButton(
                                    icon: const Icon(Icons.bookmark_border),
                                    color: Colors.white,
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.settings),
                                    color: Colors.white,
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                              body: RepaintBoundary(
                                child: ScrollablePositionedList.builder(
                                  key: ValueKey('${reverse ? 'my_words' : 'words'}_$currentIndex'),
                                  itemCount: words.length,
                                  itemScrollController: scrollController,
                                  initialScrollIndex: currentIndex,
                                  initialAlignment: 0.0,
                                  addAutomaticKeepAlives: true,
                                  addSemanticIndexes: false,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return RepaintBoundary(
                                      child: reverse
                                          ? MyWordCard(
                                              word: words[index],
                                              displayIndex: index + 1,
                                            )
                                          : WordCard(
                                              word: words[index],
                                              isExpanded: expandedIndex == index,
                                              onExpandChanged: onExpandChanged,
                                              onMarkChanged: onMarkChanged,
                                              onBookmarkChanged: onBookmarkChanged,
                                            ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // 后90度（新页面）
                AnimatedBuilder(
                  animation: curvedAnimation,
                  builder: (context, _) {
                    final value = curvedAnimation.value;
                    final angle = value * math.pi;
                    
                    if (value <= 0.5) return const SizedBox.shrink();

                    return Opacity(
                      opacity: (value - 0.5) * 2,
                      child: Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.002)
                          ..rotateY(reverse ? -angle + math.pi : angle),
                        alignment: Alignment.center,
                        child: Transform(
                          transform: Matrix4.identity()
                            ..rotateY(math.pi),
                          alignment: Alignment.center,
                          child: AbsorbPointer(
                            absorbing: value < 1.0,
                            child: DefaultTextStyle(
                              style: const TextStyle(
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                              child: Scaffold(
                                backgroundColor: Colors.transparent,
                                body: child,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
} 