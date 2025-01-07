import 'package:flutter/material.dart';
import 'dart:math' as math;

class FlipAnimation extends StatefulWidget {
  final bool showBackWidget;
  final Widget frontWidget;
  final Widget backWidget;
  final VoidCallback? onFlipComplete;

  const FlipAnimation({
    Key? key,
    required this.showBackWidget,
    required this.frontWidget,
    required this.backWidget,
    this.onFlipComplete,
  }) : super(key: key);

  @override
  _FlipAnimationState createState() => _FlipAnimationState();
}

class _FlipAnimationState extends State<FlipAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showBackWidget = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _showBackWidget = widget.showBackWidget;
    if (_showBackWidget) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FlipAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showBackWidget != oldWidget.showBackWidget) {
      if (widget.showBackWidget) {
        _controller.forward().then((_) {
          widget.onFlipComplete?.call();
        });
      } else {
        _controller.reverse().then((_) {
          widget.onFlipComplete?.call();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        final angle = value * math.pi;
        final isBack = value >= 0.5;

        return Stack(
          children: [
            // 前90度动画
            if (!isBack) ClipPath(
              clipper: _FlipClipper(angle: angle),
              child: ClipRect(
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(-angle),
                  alignment: Alignment.center,
                  child: _buildFrontWidget(value),
                ),
              ),
            ),
            // 后90度动画
            if (isBack) ClipPath(
              clipper: _FlipClipper(angle: math.pi - angle),
              child: ClipRect(
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(-angle),
                  alignment: Alignment.center,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBackWidget(value),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFrontWidget(double value) {
    return Opacity(
      opacity: 1 - value * 2,
      child: widget.frontWidget,
    );
  }

  Widget _buildBackWidget(double value) {
    return Opacity(
      opacity: (value - 0.5) * 2,
      child: widget.backWidget,
    );
  }
}

class _ClipWidget extends StatelessWidget {
  final Widget child;
  final double angle;

  const _ClipWidget({
    Key? key,
    required this.child,
    required this.angle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _FlipClipper(angle: angle),
      child: child,
    );
  }
}

class _FlipClipper extends CustomClipper<Path> {
  final double angle;

  _FlipClipper({required this.angle});

  @override
  Path getClip(Size size) {
    final path = Path();
    if (angle < math.pi / 2) {
      final width = size.width * math.cos(angle);
      path.addRect(Rect.fromLTWH(0, 0, width, size.height));
    }
    return path;
  }

  @override
  bool shouldReclip(_FlipClipper oldClipper) => angle != oldClipper.angle;
} 