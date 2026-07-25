import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/core.dart';
import '../../theme/motion.dart';
import '../../theme/theme.dart';

/// Floating assistant button that the user can drag to either side of the
/// screen.
///
/// The resting place is stored as a *fraction* of the usable area rather than
/// as absolute pixels, and it is re-resolved on every layout. That is what
/// keeps the button on screen when the device rotates, when an iPad Split View
/// pane is dragged to a new width, or when the software keyboard changes the
/// visible height — an absolute offset captured once would strand it off the
/// edge in all three cases.
class AssistantDraggableFab extends StatefulWidget {
  final Widget child;

  const AssistantDraggableFab({super.key, required this.child});

  @override
  State<AssistantDraggableFab> createState() => _AssistantDraggableFabState();
}

class _AssistantDraggableFabState extends State<AssistantDraggableFab> {
  /// Which edge the button is parked against.
  bool _onStartEdge = true;

  /// Vertical rest position, 0 = top of the usable band, 1 = bottom.
  double _verticalFraction = 0.78;

  bool _dragging = false;

  static const double _fabSize = 56;
  static const double _edgeGap = 16;

  /// Clearance kept above the bottom so the button never sits on top of the
  /// floating navigation bar or the home indicator.
  static const double _bottomReserve = 96;

  /// Clearance kept below the top bar.
  static const double _topReserve = 12;

  void _openAssistant() => context.push('/assistant');

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveLayout.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Band the button is allowed to rest in, already clear of the
              // status bar, the home indicator and the floating nav bar.
              final minY = responsive.padding.top + _topReserve;
              final maxY =
                  constraints.maxHeight -
                  responsive.padding.bottom -
                  _bottomReserve -
                  _fabSize;
              final usableHeight = (maxY - minY).clamp(0.0, double.infinity);

              final top = minY + usableHeight * _verticalFraction;

              final startInset = _edgeGap + responsive.padding.left;
              final endInset = _edgeGap + responsive.padding.right;
              final parkedLeft = _onStartEdge == isRtl
                  ? constraints.maxWidth - _fabSize - endInset
                  : startInset;

              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: _dragging
                        ? Duration.zero
                        : motionDuration(context, AppMotion.standard),
                    curve: AppMotion.enter,
                    left: parkedLeft,
                    top: top,
                    width: _fabSize,
                    height: _fabSize,
                    child: Draggable<Object>(
                      feedback: _AssistantFabButton(
                        isDark: isDark,
                        isDragging: true,
                      ),
                      childWhenDragging: const SizedBox.shrink(),
                      onDragStarted: () => setState(() => _dragging = true),
                      onDraggableCanceled: (_, _) =>
                          setState(() => _dragging = false),
                      onDragEnd: (details) {
                        final box = context.findRenderObject() as RenderBox?;
                        final local =
                            box?.globalToLocal(details.offset) ??
                            details.offset;

                        // Snap to whichever edge the drop is closest to, and
                        // store the vertical rest point as a fraction so the
                        // next layout re-derives it for the new size.
                        final droppedPastMiddle =
                            local.dx + _fabSize / 2 > constraints.maxWidth / 2;
                        final onStart = isRtl
                            ? droppedPastMiddle
                            : !droppedPastMiddle;

                        final fraction = usableHeight <= 0
                            ? 0.0
                            : ((local.dy - minY) / usableHeight).clamp(
                                0.0,
                                1.0,
                              );

                        setState(() {
                          _dragging = false;
                          _onStartEdge = onStart;
                          _verticalFraction = fraction;
                        });
                      },
                      child: _AssistantFabButton(
                        isDark: isDark,
                        onTap: _openAssistant,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AssistantFabButton extends StatelessWidget {
  final bool isDark;
  final bool isDragging;
  final VoidCallback? onTap;

  const _AssistantFabButton({
    required this.isDark,
    this.isDragging = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryBright : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: Semantics(
        button: true,
        label: 'المساعد الذكي',
        hint: 'افتح محادثة المساعد، أو اسحب لتغيير مكان الزر',
        child: PressableScale(
          pressedScale: 0.9,
          onTap: onTap,
          child: Container(
            width: _AssistantDraggableFabState._fabSize,
            height: _AssistantDraggableFabState._fabSize,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: isDragging ? 0.6 : 0.3),
                  blurRadius: isDragging ? 24 : 12,
                  spreadRadius: isDragging ? 4 : 0,
                  offset: Offset(0, isDragging ? 8 : 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
