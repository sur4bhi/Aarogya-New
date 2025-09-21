import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

class AppAnimations {
  static const Duration canvasBlurToCrisp = Duration(milliseconds: 700);
  static const Duration cardElevate = Duration(milliseconds: 200);
  static const Duration ctaStaggerMin = Duration(milliseconds: 100);
  static const Duration ctaStaggerMax = Duration(milliseconds: 140);
  static const Duration sosPulse = Duration(milliseconds: 1200);

  static const Curve ease = Curves.ease;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
}

class Pulse extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scaleBegin;
  final double scaleEnd;

  const Pulse({super.key, required this.child, this.duration = AppAnimations.sosPulse, this.scaleBegin = 1.0, this.scaleEnd = 1.2});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
    _scale = Tween<double>(begin: widget.scaleBegin, end: widget.scaleEnd).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacity = Tween<double>(begin: 1.0, end: 0.7).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(opacity: _opacity.value, child: Transform.scale(scale: _scale.value, child: child)),
      child: widget.child,
    );
  }
}