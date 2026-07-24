import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 120);

  static const Duration quick = Duration(milliseconds: 200);

  static const Duration standard = Duration(milliseconds: 300);

  static const Duration emphasized = Duration(milliseconds: 420);

  static const Duration deliberate = Duration(milliseconds: 560);

  static const Curve enter = Cubic(0.16, 1.0, 0.3, 1.0);

  static const Curve exit = Cubic(0.4, 0.0, 1.0, 1.0);

  static const Curve standardCurve = Cubic(0.4, 0.0, 0.2, 1.0);

  static const Curve overshoot = Cubic(0.34, 1.42, 0.64, 1.0);

  static const SpringDescription smooth = SpringDescription(
    mass: 1.0,
    stiffness: 180.0,
    damping: 26.83,
  );

  static const SpringDescription snappy = SpringDescription(
    mass: 1.0,
    stiffness: 220.0,
    damping: 22.25,
  );

  static const SpringDescription gentle = SpringDescription(
    mass: 1.4,
    stiffness: 140.0,
    damping: 28.0,
  );

  static TickerFuture springTo(
    AnimationController controller,
    double target, {
    SpringDescription spring = snappy,
  }) {
    return controller.animateWith(
      SpringSimulation(spring, controller.value, target, controller.velocity),
    );
  }
}

bool prefersReducedMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

Duration motionDuration(BuildContext context, Duration duration) =>
    prefersReducedMotion(context) ? Duration.zero : duration;

class MotionSize extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Alignment alignment;

  const MotionSize({
    super.key,
    required this.child,
    this.duration = AppMotion.standard,
    this.curve = AppMotion.enter,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    if (prefersReducedMotion(context)) return child;
    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: alignment,
      child: child,
    );
  }
}
