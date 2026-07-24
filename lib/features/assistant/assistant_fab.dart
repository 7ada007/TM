import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../core/shared_widgets.dart';
import 'assistant_chat_screen.dart';

class AssistantDraggableFab extends StatefulWidget {
  final Widget child;

  const AssistantDraggableFab({super.key, required this.child});

  @override
  State<AssistantDraggableFab> createState() => _AssistantDraggableFabState();
}

class _AssistantDraggableFabState extends State<AssistantDraggableFab> {
  Offset _position = const Offset(20, 100);
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final size = MediaQuery.of(context).size;
        setState(() {
          _position = Offset(20, size.height - 160);
          _isInitialized = true;
        });
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        widget.child,
        if (_isInitialized)
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: Draggable(
              feedback: _buildFab(isDark, isDragging: true),
              childWhenDragging: const SizedBox.shrink(),
              onDragEnd: (details) {
                final size = MediaQuery.of(context).size;
                final safeTop = MediaQuery.of(context).padding.top + 20;
                final safeBottom = size.height - 100;

                double newX = details.offset.dx;
                double newY = details.offset.dy;

                if (newX > size.width / 2) {
                  newX = size.width - 70;
                } else {
                  newX = 16;
                }

                if (newY < safeTop) newY = safeTop;
                if (newY > safeBottom) newY = safeBottom;

                setState(() {
                  _position = Offset(newX, newY);
                });
              },
              child: _buildFab(isDark),
            ),
          ),
      ],
    );
  }

  Widget _buildFab(bool isDark, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: PressableScale(
        pressedScale: 0.9,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AssistantChatScreen(),
            ),
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: isDragging ? 0.6 : 0.3,
                ),
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
    );
  }
}
