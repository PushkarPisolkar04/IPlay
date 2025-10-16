import 'package:flutter/material.dart';

class XPCounterAnimated extends StatefulWidget {
  final int startValue;
  final int endValue;
  final Duration duration;

  const XPCounterAnimated({
    Key? key,
    required this.startValue,
    required this.endValue,
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<XPCounterAnimated> createState() => _XPCounterAnimatedState();
}

class _XPCounterAnimatedState extends State<XPCounterAnimated> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = IntTween(begin: widget.startValue, end: widget.endValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
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
      builder: (context, child) => Text('${_animation.value} XP'),
    );
  }
}

