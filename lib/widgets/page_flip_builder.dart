import 'package:flutter/material.dart';
import 'dart:math' as math;

class PageFlipBuilder extends StatefulWidget {
  final Widget frontWidget;
  final Widget backWidget;
  final VoidCallback? onFlipComplete;
  final bool reverse;

  const PageFlipBuilder({
    Key? key,
    required this.frontWidget,
    required this.backWidget,
    this.onFlipComplete,
    this.reverse = false,
  }) : super(key: key);

  @override
  PageFlipBuilderState createState() => PageFlipBuilderState();
}

class PageFlipBuilderState extends State<PageFlipBuilder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFrontSide = true;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _animation.addStatusListener(_updateStatus);
  }

  void _updateStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
      widget.onFlipComplete?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void flip() {
    if (_controller.isAnimating) return;
    if (_controller.status == AnimationStatus.dismissed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * math.pi;
        final showFront = angle < math.pi / 2;
        
        return Stack(
          children: [
            // 前90度
            if (angle <= math.pi / 2) Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateY(widget.reverse ? angle : -angle),
              alignment: Alignment.center,
              child: widget.frontWidget,
            ),
            
            // 后90度
            if (angle > math.pi / 2) Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateY(widget.reverse ? angle : -angle)
                ..rotateY(math.pi),
              alignment: Alignment.center,
              child: widget.backWidget,
            ),
          ],
        );
      },
    );
  }
}

// 自定义裁剪器，用于处理翻转过程中的视觉效果
class FlipClipper extends CustomClipper<Path> {
  final double angle;
  final bool isLeft;

  FlipClipper(this.angle, this.isLeft);

  @override
  Path getClip(Size size) {
    final path = Path();
    if (isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width * (1 - angle / math.pi), 0);
      path.lineTo(size.width * (1 - angle / math.pi), size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width * (angle / math.pi), 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width * (angle / math.pi), size.height);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
} 