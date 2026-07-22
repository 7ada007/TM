import '../../core/core.dart';
import '../../theme/theme.dart';
import '../auth/auth.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class StarRatingWidget extends StatelessWidget {
  final double rating;
  final int? userRating;
  final int ratingCount;
  final bool interactive;
  final ValueChanged<int>? onRatingChanged;
  final double starSize;
  final bool showSummary;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.userRating,
    this.ratingCount = 0,
    this.interactive = false,
    this.onRatingChanged,
    this.starSize = 24,
    this.showSummary = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayRating = interactive ? (userRating ?? 0).toDouble() : rating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1;
            final filled = displayRating >= starValue - 0.25;
            final half = !filled && displayRating >= starValue - 0.75;

            return Padding(
              padding: const EdgeInsets.only(left: 2),
              child: GestureDetector(
                onTap: interactive && onRatingChanged != null
                    ? () {
                        HapticFeedback.selectionClick();
                        onRatingChanged!(starValue);
                      }
                    : null,
                child: AnimatedScale(
                  scale:
                      interactive &&
                          userRating != null &&
                          userRating == starValue
                      ? 1.08
                      : 1,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    filled
                        ? Icons.star_rounded
                        : half
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded,
                    size: starSize,
                    color: filled || half
                        ? const Color(0xFFFFB300)
                        : AppColors.border(context),
                  ),
                ),
              ),
            );
          }),
        ),
        if (showSummary) ...[
          const SizedBox(height: 6),
          Text(
            ratingCount == 0
                ? 'لا توجد تقييمات بعد'
                : '${rating.toStringAsFixed(1)} • $ratingCount تقييم',
            style: AppFonts.readex(
              fontSize: 12,
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class LectureRatingBadge extends StatelessWidget {
  final double average;
  final int count;

  const LectureRatingBadge({
    super.key,
    required this.average,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
          const SizedBox(width: 3),
          Text(
            average.toStringAsFixed(1),
            style: AppFonts.readex(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

enum UploadStatus { idle, uploading, success, failure }

class UploadProgressWidget extends StatelessWidget {
  final UploadStatus status;
  final double progress;
  final String? fileName;
  final String? speedLabel;
  final String? etaLabel;
  final String? errorMessage;

  const UploadProgressWidget({
    super.key,
    this.status = UploadStatus.idle,
    this.progress = 0,
    this.fileName,
    this.speedLabel,
    this.etaLabel,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (status == UploadStatus.idle) return const SizedBox.shrink();

    final isSuccess = status == UploadStatus.success;
    final isFailure = status == UploadStatus.failure;
    final isUploading = status == UploadStatus.uploading;
    final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);

    Color accentColor = AppColors.secondary;
    IconData icon = Icons.cloud_upload_rounded;
    String title = 'جاري الرفع...';

    if (isSuccess) {
      accentColor = const Color(0xFF2E7D32);
      icon = Icons.check_circle_rounded;
      title = 'تم الرفع بنجاح';
    } else if (isFailure) {
      accentColor = AppColors.error;
      icon = Icons.error_outline_rounded;
      title = 'فشل الرفع';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accentColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.readex(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                        fontSize: 14,
                      ),
                    ),
                    if (fileName != null && fileName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        fileName!,
                        style: AppFonts.readex(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (isUploading)
                Text(
                  '$percent%',
                  style: AppFonts.readex(
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
          if (isUploading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? AppColors.overlay(0.12)
                        : AppColors.primary.withValues(alpha: 0.08),
                    color: accentColor,
                  );
                },
              ),
            ),
            if (speedLabel != null || etaLabel != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (speedLabel != null) ...[
                    Icon(
                      Icons.speed_rounded,
                      size: 14,
                      color: AppColors.textSecondary(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      speedLabel!,
                      style: AppFonts.readex(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (etaLabel != null) ...[
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.textSecondary(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      etaLabel!,
                      style: AppFonts.readex(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
          if (isFailure && errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: AppFonts.readex(fontSize: 12, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

String formatFileSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  return '${size.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
}

String formatUploadSpeed(double bytesPerSecond) {
  return '${formatFileSize(bytesPerSecond.round())}/s';
}

String formatEta(Duration remaining) {
  if (remaining.inHours > 0) {
    return 'متبقي ${remaining.inHours}س ${remaining.inMinutes.remainder(60)}د';
  }
  if (remaining.inMinutes > 0) {
    return 'متبقي ${remaining.inMinutes}د ${remaining.inSeconds.remainder(60)}ث';
  }
  return 'متبقي ${remaining.inSeconds}ث';
}

class CommentTile extends StatefulWidget {
  final CommentModel comment;
  final int animationIndex;

  const CommentTile({
    super.key,
    required this.comment,
    this.animationIndex = 0,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('d MMM yyyy • h:mm a', 'ar').format(dt);
  }

  Future<void> _confirmDelete() async {
    final data = context.read<ApiDataService>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التعليق'),
        content: const Text('هل تريد حذف تعليقك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await data.deleteLectureComment(widget.comment.id);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(cleanErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final user = context.watch<AuthService>().currentUser;
    final canDelete = PermissionUtils.canDeleteComment(
      user: user,
      comment: comment,
    );
    final remaining = PermissionUtils.commentDeletableFor(
      user: user,
      comment: comment,
    );

    return AppCard(
          margin: const EdgeInsets.only(bottom: AppLayout.itemGap),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    name: comment.userName,
                    photoPath: comment.userPhotoPath,
                    size: 44,
                    showBorder: false,
                    showShadow: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                comment.userName,
                                style: AppFonts.readex(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                            ),
                            Text(
                              _formatDateTime(comment.createdAt),
                              style: AppFonts.readex(
                                fontSize: 10,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          comment.content,
                          style: AppFonts.readex(
                            fontSize: 14,
                            height: 1.45,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canDelete) ...[
                    const SizedBox(width: 4),
                    PressableScale(
                      pressedScale: 0.85,
                      onTap: _confirmDelete,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.error.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (remaining != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: AppColors.textSecondary(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'يمكنك حذف تعليقك خلال ${remaining.inMinutes} دقيقة',
                      style: AppFonts.readex(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(
          duration: 320.ms,
          delay: (widget.animationIndex * 60).ms,
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.08,
          end: 0,
          duration: 320.ms,
          delay: (widget.animationIndex * 60).ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class LectureRatingSection extends StatelessWidget {
  final String lectureId;

  const LectureRatingSection({super.key, required this.lectureId});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final userId = auth.currentUser?.id;

    return Selector<ApiDataService, LectureRatingSummary>(
      selector: (_, data) =>
          data.getRatingSummary(lectureId: lectureId, userId: userId),
      builder: (context, summary, _) {
        final canRate =
            PermissionUtils.canRateLecture(auth.currentUser) && userId != null;

        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تقييم المحاضرة',
                style: AppFonts.readex(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppLayout.itemGap),
              StarRatingWidget(
                rating: summary.average,
                userRating: summary.userStars,
                ratingCount: summary.count,
                interactive: canRate,
                onRatingChanged: canRate
                    ? (stars) async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await context
                              .read<ApiDataService>()
                              .setLectureRatingData(
                                lectureId: lectureId,
                                userId: userId,
                                stars: stars,
                              );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceFirst('Exception: ', ''),
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    : null,
              ),
              if (!canRate && summary.count > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'متوسط تقييم الطلاب لهذه المحاضرة',
                  style: AppFonts.readex(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
              if (canRate) ...[
                const SizedBox(height: 8),
                Text(
                  summary.userStars == null
                      ? 'اضغط على النجوم لتقييم المحاضرة'
                      : 'تقييمك: ${summary.userStars} نجوم',
                  style: AppFonts.readex(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class LectureCommentsSection extends StatefulWidget {
  final String lectureId;

  const LectureCommentsSection({super.key, required this.lectureId});

  @override
  State<LectureCommentsSection> createState() => _LectureCommentsSectionState();
}

class _LectureCommentsSectionState extends State<LectureCommentsSection> {
  final _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isPosting) return;

    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isPosting = true);
    HapticFeedback.lightImpact();

    try {
      await context.read<ApiDataService>().addCommentData(
        lectureId: widget.lectureId,
        userId: user.id,
        userName: user.name,
        userPhotoPath: user.photoPath,
        content: content,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _commentController.clear();
    if (mounted) setState(() => _isPosting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Selector<ApiDataService, int>(
          selector: (_, data) =>
              data.getCommentsForLecture(widget.lectureId).length,
          builder: (context, count, _) {
            return Row(
              children: [
                Text(
                  'التعليقات',
                  style: AppFonts.readex(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: AppFonts.readex(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppLayout.itemGap),
        Selector<ApiDataService, List<CommentModel>>(
          selector: (_, data) => data.getCommentsForLecture(widget.lectureId),
          shouldRebuild: (prev, next) =>
              prev.length != next.length ||
              (prev.isNotEmpty &&
                  next.isNotEmpty &&
                  prev.first.id != next.first.id),
          builder: (context, comments, _) {
            if (comments.isEmpty) {
              return AppCard(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 40,
                      color: AppColors.icon(context).withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'لا توجد تعليقات بعد',
                      style: AppFonts.readex(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppLayout.itemGap),
              itemBuilder: (context, index) {
                return RepaintBoundary(
                  child: CommentTile(
                    key: ValueKey(comments[index].id),
                    comment: comments[index],
                    animationIndex: index.clamp(0, 6),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: AppLayout.blockGap),
        _CommentInputBar(
          controller: _commentController,
          isPosting: _isPosting,
          onPost: _postComment,
        ),
      ],
    );
  }
}

class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isPosting;
  final VoidCallback onPost;

  const _CommentInputBar({
    required this.controller,
    required this.isPosting,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      borderRadius: AppRadius.lg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onPost(),
              style: AppFonts.readex(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'اكتب تعليقك...',
                hintStyle: AppFonts.readex(
                  color: AppColors.textSecondary(context),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(
            pressedScale: 0.9,
            onTap: isPosting ? null : onPost,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isPosting ? null : AppColors.primaryGradient,
                color: isPosting
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: isPosting
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: AppLoadingIndicator(size: 20),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumLectureCard extends StatefulWidget {
  final LectureModel lecture;
  final bool showFavorite;
  final bool showManageMenu;
  final int animationIndex;
  final VoidCallback? onManageChanged;

  const PremiumLectureCard({
    super.key,
    required this.lecture,
    this.showFavorite = true,
    this.showManageMenu = false,
    this.animationIndex = 0,
    this.onManageChanged,
  });

  @override
  State<PremiumLectureCard> createState() => _PremiumLectureCardState();
}

class _PremiumLectureCardState extends State<PremiumLectureCard> {
  void _openDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    context.push('/lecture/${widget.lecture.id}');
  }

  @override
  Widget build(BuildContext context) {
    final lecture = widget.lecture;
    final colors = AppSubjects.gradientFor(lecture.subject);
    final coverPath = lecture.coverImagePath;
    final hasCover =
        coverPath != null &&
        coverPath.isNotEmpty &&
        (MediaUrl.isRemote(coverPath) || File(coverPath).existsSync());

    return Selector<ApiDataService, ({double avg, int count, bool favorite})>(
      selector: (_, data) => (
        avg: data.getAverageRating(lecture.id),
        count: data.getRatingCount(lecture.id),
        favorite:
            data.findLectureById(lecture.id)?.isFavorite ?? lecture.isFavorite,
      ),
      builder: (context, state, _) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 320 + widget.animationIndex * 60),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, (1 - value) * 16),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: PressableScale(
            pressedScale: 0.98,
            onTap: () => _openDetail(context),
            child: AppCard(
              margin: const EdgeInsets.only(bottom: AppLayout.cardGap),
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg),
                    ),
                    child: SizedBox(
                      height: 150,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (hasCover)
                            MediaUrl.isRemote(coverPath)
                                ? Image.network(
                                    MediaUrl.resolve(coverPath),
                                    fit: BoxFit.cover,
                                    cacheWidth: 720,
                                    gaplessPlayback: true,
                                    errorBuilder: (_, _, _) =>
                                        const SizedBox.shrink(),
                                  )
                                : Image.file(
                                    File(coverPath),
                                    fit: BoxFit.cover,
                                    cacheWidth: 720,
                                    gaplessPlayback: true,
                                  )
                          else
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: colors
                                      .map((c) => c.withValues(alpha: 0.85))
                                      .toList(),
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child:
                                  AppSubjects.bannerAssetFor(lecture.subject) !=
                                      null
                                  ? Image.asset(
                                      AppSubjects.bannerAssetFor(
                                        lecture.subject,
                                      )!,
                                      fit: BoxFit.cover,
                                      color: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      colorBlendMode: BlendMode.darken,
                                      errorBuilder: (_, _, _) =>
                                          const SizedBox.shrink(),
                                    )
                                  : null,
                            ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.45),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 14,
                            top: 14,
                            child: SubjectIcon(
                              subject: lecture.subject,
                              size: 40,
                            ),
                          ),
                          if (widget.showManageMenu)
                            Positioned(
                              left: 10,
                              top: 10,
                              child: GestureDetector(
                                onTap: () {},
                                behavior: HitTestBehavior.opaque,
                                child: LectureManageMenu(
                                  lecture: lecture,
                                  onChanged: widget.onManageChanged,
                                ),
                              ),
                            ),
                          Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          if (lecture.duration != null)
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  lecture.duration!,
                                  style: AppFonts.readex(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                lecture.title,
                                style: AppFonts.readex(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.showFavorite)
                              PressableScale(
                                pressedScale: 0.85,
                                onTap: () => context
                                    .read<ApiDataService>()
                                    .toggleLectureFavorite(lecture.id),
                                child: Icon(
                                  state.favorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: state.favorite
                                      ? AppColors.error
                                      : AppColors.textSecondary(context),
                                  size: 22,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: AppColors.primary.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lecture.teacherName.trim().isNotEmpty
                                    ? lecture.teacherName
                                    : (context
                                              .read<ApiDataService>()
                                              .findUserById(lecture.teacherId)
                                              ?.name ??
                                          'غير محدّد'),
                                style: AppFonts.readex(
                                  fontSize: 13,
                                  color: AppColors.textSecondary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: AppColors.textSecondary(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lecture.date,
                              style: AppFonts.readex(
                                fontSize: 12,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                            if (state.count > 0) ...[
                              const SizedBox(width: 8),
                              LectureRatingBadge(
                                average: state.avg,
                                count: state.count,
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                lecture.section,
                                style: AppFonts.readex(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PremiumSubjectDropdown extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> subjects;
  final bool enabled;

  const PremiumSubjectDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.subjects = AppSubjects.all,
    this.enabled = true,
  });

  @override
  State<PremiumSubjectDropdown> createState() => _PremiumSubjectDropdownState();
}

class _PremiumSubjectDropdownState extends State<PremiumSubjectDropdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _menuController;
  late final Animation<double> _expand;
  late final Animation<double> _fade;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _expand = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fade = CurvedAnimation(
      parent: _menuController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  Future<void> _toggleMenu() async {
    if (!widget.enabled) return;
    HapticFeedback.selectionClick();
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      await _menuController.forward();
    } else {
      await _menuController.reverse();
    }
  }

  Future<void> _select(String subject) async {
    if (!widget.enabled || subject == widget.value) {
      if (_isOpen) await _toggleMenu();
      return;
    }
    HapticFeedback.lightImpact();
    widget.onChanged(subject);
    if (_isOpen) await _toggleMenu();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppSubjects.gradientFor(widget.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? _toggleMenu : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.overlay(0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: _isOpen
                      ? colors.first.withValues(alpha: 0.55)
                      : AppColors.border(context),
                  width: _isOpen ? 1.6 : 1,
                ),
                boxShadow: _isOpen
                    ? [
                        BoxShadow(
                          color: colors.first.withValues(alpha: 0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : AppShadows.soft(blur: 10),
              ),
              child: Row(
                children: [
                  SubjectIcon(subject: widget.value, size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المادة',
                          style: AppFonts.readex(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.value,
                          style: AppFonts.readex(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.enabled
                          ? AppColors.icon(context)
                          : AppColors.textSecondary(
                              context,
                            ).withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ClipRect(
          child: AnimatedBuilder(
            animation: _expand,
            builder: (context, child) {
              return Align(
                alignment: Alignment.topCenter,
                heightFactor: _expand.value,
                child: Opacity(opacity: _fade.value, child: child),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surface(context)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border(context)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(widget.subjects.length, (index) {
                    final subject = widget.subjects[index];
                    final isSelected = subject == widget.value;
                    final delay = index * 0.06;
                    final subjectColors = AppSubjects.gradientFor(subject);

                    return AnimatedBuilder(
                      animation: _menuController,
                      builder: (context, child) {
                        final slide = Curves.easeOutCubic.transform(
                          ((_menuController.value - delay) / (1 - delay)).clamp(
                            0.0,
                            1.0,
                          ),
                        );
                        return Transform.translate(
                          offset: Offset(0, (1 - slide) * 12),
                          child: Opacity(opacity: slide, child: child),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SubjectOptionTile(
                          subject: subject,
                          isSelected: isSelected,
                          colors: subjectColors,
                          enabled: widget.enabled,
                          onTap: () => _select(subject),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubjectOptionTile extends StatefulWidget {
  final String subject;
  final bool isSelected;
  final List<Color> colors;
  final bool enabled;
  final VoidCallback onTap;

  const _SubjectOptionTile({
    required this.subject,
    required this.isSelected,
    required this.colors,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_SubjectOptionTile> createState() => _SubjectOptionTileState();
}

class _SubjectOptionTileState extends State<_SubjectOptionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: widget.enabled
          ? () => setState(() => _pressed = false)
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(colors: widget.colors)
                : null,
            color: widget.isSelected
                ? null
                : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.overlay(0.08)
                      : AppColors.primary.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.transparent
                  : AppColors.border(context),
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.colors.first.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              SubjectIcon(subject: widget.subject, size: 36, showShadow: false),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.subject,
                  style: AppFonts.readex(
                    fontWeight: FontWeight.w600,
                    color: widget.isSelected
                        ? Colors.white
                        : AppColors.textPrimary(context),
                  ),
                ),
              ),
              Icon(
                widget.isSelected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: widget.isSelected
                    ? Colors.white
                    : AppColors.textSecondary(context).withValues(alpha: 0.35),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool?> showDeleteLectureDialog(
  BuildContext context, {
  required LectureModel lecture,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'إلغاء',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _DeleteLectureDialog(lecture: lecture);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _DeleteLectureDialog extends StatelessWidget {
  final LectureModel lecture;

  const _DeleteLectureDialog({required this.lecture});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.88,
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.all(20),
          child: AppCard(
            padding: const EdgeInsets.all(22),
            borderRadius: AppRadius.xl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'حذف المحاضرة',
                  style: AppFonts.readex(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'هل أنت متأكد من حذف "${lecture.title}"؟\nلا يمكن التراجع عن هذا الإجراء.',
                  textAlign: TextAlign.center,
                  style: AppFonts.readex(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 22),
                PressableScale(
                  onTap: () async {
                    final dataService = context.read<ApiDataService>();
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await dataService.deleteLecture(lecture.id);
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst('Exception: ', ''),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    navigator.pop(true);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC62828), Color(0xFFE53935)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'حذف المحاضرة',
                        style: AppFonts.readex(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                PremiumActionButton(
                  label: 'إلغاء',
                  isOutlined: true,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LectureManageMenu extends StatelessWidget {
  final LectureModel lecture;
  final VoidCallback? onChanged;

  const LectureManageMenu({super.key, required this.lecture, this.onChanged});

  Future<void> _handleEdit(BuildContext context) async {
    final result = await showEditLectureDialog(context, lecture: lecture);
    if (result == true) onChanged?.call();
  }

  Future<void> _handleDelete(BuildContext context) async {
    final result = await showDeleteLectureDialog(context, lecture: lecture);
    if (result == true) onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!LecturePermissions.canManageLecture(auth: auth, lecture: lecture)) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurfaceElevated.withValues(alpha: 0.98)
          : Colors.white,
      elevation: 8,
      offset: const Offset(0, 40),
      onSelected: (value) {
        HapticFeedback.selectionClick();
        if (value == 'edit') {
          _handleEdit(context);
        } else if (value == 'delete') {
          _handleDelete(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_rounded,
                color: AppColors.icon(context),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'تعديل المحاضرة',
                style: AppFonts.readex(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'حذف المحاضرة',
                style: AppFonts.readex(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StudentSubjectGrid extends StatelessWidget {
  final List<String> subjects;
  final Map<String, int> lectureCounts;
  final ValueChanged<String> onSubjectTap;

  const StudentSubjectGrid({
    super.key,
    required this.subjects,
    required this.lectureCounts,
    required this.onSubjectTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: AppLayout.listPadding(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppLayout.itemGap,
        crossAxisSpacing: AppLayout.itemGap,
        childAspectRatio: 0.92,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final count = lectureCounts[subject] ?? 0;
        return _SubjectCard(
          subject: subject,
          lectureCount: count,
          animationIndex: index,
          onTap: () {
            HapticFeedback.selectionClick();
            onSubjectTap(subject);
          },
        );
      },
    );
  }
}

class _SubjectCard extends StatefulWidget {
  final String subject;
  final int lectureCount;
  final int animationIndex;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.subject,
    required this.lectureCount,
    required this.animationIndex,
    required this.onTap,
  });

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  @override
  Widget build(BuildContext context) {
    final colors = AppSubjects.gradientFor(widget.subject);
    final banner = AppSubjects.bannerAssetFor(widget.subject);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + widget.animationIndex * 70),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: PressableScale(
        pressedScale: 0.96,
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (banner != null)
                  Image.asset(
                    banner,
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.25),
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (_, _, _) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                      ),
                    ),
                  )
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SubjectIcon(subject: widget.subject, size: 44),
                      const Spacer(),
                      Text(
                        widget.subject,
                        style: AppFonts.readex(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${widget.lectureCount} محاضرة',
                          style: AppFonts.readex(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StudentLectureList extends StatelessWidget {
  final String subject;
  final int lectureCount;
  final List<Widget> lectures;
  final VoidCallback onBack;

  const StudentLectureList({
    super.key,
    required this.subject,
    required this.lectureCount,
    required this.lectures,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppSubjects.gradientFor(subject);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.pageHorizontal,
            AppLayout.pageTop,
            AppLayout.pageHorizontal,
            0,
          ),
          child: Row(
            children: [
              PressableScale(
                pressedScale: 0.9,
                onTap: onBack,
                child: Builder(
                  builder: (context) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.overlay(0.10)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border(context)),
                        boxShadow: AppShadows.of(Theme.of(context).brightness),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.icon(context),
                        size: 18,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: AppFonts.readex(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.first,
                      ),
                    ),
                    Text(
                      '$lectureCount محاضرة • مرتبة زمنياً',
                      style: AppFonts.readex(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppLayout.itemGap),
        Expanded(
          child: lectures.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 56,
                        color: AppColors.icon(context).withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد محاضرات في هذه المادة',
                        style: AppFonts.readex(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: AppLayout.listPadding(),
                  itemCount: lectures.length,
                  itemBuilder: (context, index) {
                    return lectures[index];
                  },
                ),
        ),
      ],
    );
  }
}

class PremiumVideoPlayer extends StatefulWidget {
  final String videoPath;
  final String? posterPath;
  final ValueChanged<Duration>? onDurationResolved;

  const PremiumVideoPlayer({
    super.key,
    required this.videoPath,
    this.posterPath,
    this.onDurationResolved,
  });

  @override
  State<PremiumVideoPlayer> createState() => _PremiumVideoPlayerState();
}

class _PremiumVideoPlayerState extends State<PremiumVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  StreamInfo? _streamInfo;
  String? _activeUrl;
  Duration? _resumeAt;
  bool _resumePlaying = false;
  String _qualityLabel = 'تلقائي';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializePlayer());
  }

  @override
  void didUpdateWidget(covariant PremiumVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      unawaited(_initializePlayer());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        controller.pause();
        unawaited(WakelockPlus.disable());
      case AppLifecycleState.resumed:
        break;
    }
  }

  Future<void> _initializePlayer() async {
    await _disposeController();

    if (!mounted) return;
    setState(() {
      _isInitializing = true;
      _hasError = false;
      _errorMessage = null;
    });

    final isRemote = MediaUrl.isRemote(widget.videoPath);
    File? file;
    if (!isRemote) {
      file = File(widget.videoPath);
      if (!file.existsSync()) {
        if (!mounted) return;
        setState(() {
          _isInitializing = false;
          _hasError = true;
          _errorMessage = 'ملف الفيديو غير موجود على الجهاز';
        });
        return;
      }
    }

    String? networkUrl;
    if (isRemote) {
      if (_streamInfo == null) {
        _streamInfo = await resolveLectureStream(widget.videoPath);
        if (!mounted) return;
      }
      networkUrl =
          _activeUrl ??
          MediaUrl.resolve(
            _streamInfo!.play.isNotEmpty
                ? _streamInfo!.play
                : widget.videoPath,
          );
    }

    VideoPlayerController? controller;
    try {
      final options = VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      );
      controller = isRemote
          ? VideoPlayerController.networkUrl(
              Uri.parse(networkUrl!),
              videoPlayerOptions: options,
            )
          : VideoPlayerController.file(file!, videoPlayerOptions: options);
      await controller.initialize();
      controller.setLooping(false);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      final duration = controller.value.duration;
      if (duration > Duration.zero) {
        widget.onDurationResolved?.call(duration);
      }

      final resumeAt = _resumeAt;
      final resumePlaying = _resumePlaying;
      _resumeAt = null;
      if (resumeAt != null && resumeAt > Duration.zero) {
        await controller.seekTo(resumeAt);
        if (resumePlaying) {
          await controller.play();
          await WakelockPlus.enable();
        }
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
        _activeUrl = networkUrl;
      });
      _revealControls();
    } catch (error) {
      await controller?.dispose();
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMessage = 'تعذّر تحميل الفيديو. حاول مرة أخرى.';
      });
    }
  }

  Future<void> _disposeController() async {
    _hideControlsTimer?.cancel();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      if (controller.value.isPlaying) {
        await WakelockPlus.disable();
      }
      await controller.dispose();
    }
  }

  void _revealControls() {
    _hideControlsTimer?.cancel();
    if (!mounted) return;
    setState(() => _showControls = true);
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      final controller = _controller;
      if (controller != null && controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  Future<void> _togglePlayPause() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    _revealControls();
    if (controller.value.isPlaying) {
      await controller.pause();
      await WakelockPlus.disable();
    } else {
      await controller.play();
      await WakelockPlus.enable();
    }
    if (mounted) setState(() {});
  }

  Future<void> _seekRelative(Duration offset) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final current = controller.value.position;
    final target = current + offset;
    final max = controller.value.duration;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > max ? max : target);
    await controller.seekTo(clamped);
    _revealControls();
  }

  Future<void> _openFullscreen() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final position = controller.value.position;
    final wasPlaying = controller.value.isPlaying;
    await controller.pause();
    await WakelockPlus.disable();

    if (!mounted) return;
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullscreenVideoPage(
            videoPath: widget.videoPath,
            streamUrl: _activeUrl,
            initialPosition: position,
            autoPlay: wasPlaying,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    if (!mounted) return;
    final resumed = _controller;
    if (resumed != null && resumed.value.isInitialized && wasPlaying) {
      await resumed.seekTo(resumed.value.position);
    }
  }

  Future<void> _switchQuality(String fullUrl, String label) async {
    if (fullUrl == _activeUrl) return;
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      _resumeAt = controller.value.position;
      _resumePlaying = controller.value.isPlaying;
    }
    setState(() {
      _activeUrl = fullUrl;
      _qualityLabel = label;
    });
    await _initializePlayer();
  }

  void _showQualityMenu() {
    final info = _streamInfo;
    if (info == null || !info.isReady) return;
    final autoUrl = MediaUrl.resolve(
      (info.hls != null && info.hls!.isNotEmpty) ? info.hls! : info.progressive,
    );
    final options = <MapEntry<String, String>>[
      MapEntry('تلقائي', autoUrl),
      for (final v in info.variants)
        MapEntry(v.name, MediaUrl.resolve(v.playlist)),
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(sheetContext),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'جودة الفيديو',
              style: AppFonts.readex(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            ...options.map((option) {
              final selected =
                  _qualityLabel == option.key || _activeUrl == option.value;
              return ListTile(
                title: Text(
                  option.key,
                  style: AppFonts.readex(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected
                        ? AppColors.icon(sheetContext)
                        : AppColors.textPrimary(sheetContext),
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.check_rounded, color: AppColors.icon(sheetContext))
                    : null,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _switchQuality(option.value, option.key);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeController());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(color: Colors.black, child: _buildBody(context)),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isInitializing) {
      return _buildPosterOverlay(
        child: const _PlayerLoadingIndicator(label: 'جاري تحميل الفيديو...'),
      );
    }

    if (_hasError) {
      return _buildPosterOverlay(
        child: _PlayerErrorState(
          message: _errorMessage ?? 'حدث خطأ',
          onRetry: _initializePlayer,
        ),
      );
    }

    final controller = _controller!;
    return GestureDetector(
      onTap: _revealControls,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.isBuffering && value.isPlaying) {
                return const _PlayerLoadingIndicator(
                  label: 'جاري التخزين المؤقت...',
                  compact: true,
                );
              }
              return const SizedBox.shrink();
            },
          ),
          AnimatedOpacity(
            opacity: _showControls ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: IgnorePointer(
              ignoring: !_showControls,
              child: _PlayerControlsOverlay(
                controller: controller,
                onPlayPause: _togglePlayPause,
                onSeekBackward: () =>
                    _seekRelative(const Duration(seconds: -10)),
                onSeekForward: () => _seekRelative(const Duration(seconds: 10)),
                onFullscreen: _openFullscreen,
              ),
            ),
          ),
          if (_streamInfo?.isReady ?? false)
            PositionedDirectional(
              top: 10,
              end: 10,
              child: AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: PressableScale(
                    onTap: _showQualityMenu,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.hd_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _qualityLabel,
                            style: AppFonts.readex(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPosterOverlay({required Widget child}) {
    final posterPath = widget.posterPath;
    final posterIsRemote = MediaUrl.isRemote(posterPath);
    final hasPoster =
        posterPath != null &&
        posterPath.isNotEmpty &&
        (posterIsRemote || File(posterPath).existsSync());

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasPoster)
          posterIsRemote
              ? Image.network(
                  MediaUrl.resolve(posterPath),
                  fit: BoxFit.cover,
                  cacheWidth: 1280,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                )
              : Image.file(
                  File(posterPath),
                  fit: BoxFit.cover,
                  cacheWidth: 1280,
                  gaplessPlayback: true,
                )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.85),
                  AppColors.secondary.withValues(alpha: 0.65),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        Container(color: Colors.black.withValues(alpha: 0.45)),
        Center(child: child),
      ],
    );
  }
}

class _PlayerControlsOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekBackward;
  final VoidCallback onSeekForward;
  final VoidCallback onFullscreen;

  const _PlayerControlsOverlay({
    required this.controller,
    required this.onPlayPause,
    required this.onSeekBackward,
    required this.onSeekForward,
    required this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.55),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.75),
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: Column(
        children: [
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundControlButton(
                icon: Icons.replay_10_rounded,
                onTap: onSeekBackward,
              ),
              const SizedBox(width: 18),
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  return _RoundControlButton(
                    icon: value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 56,
                    onTap: onPlayPause,
                  );
                },
              ),
              const SizedBox(width: 18),
              _RoundControlButton(
                icon: Icons.forward_10_rounded,
                onTap: onSeekForward,
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final duration = value.duration;
                final position = value.position;
                final maxMs = duration.inMilliseconds;
                final progress = maxMs > 0
                    ? (position.inMilliseconds / maxMs).clamp(0.0, 1.0)
                    : 0.0;

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: AppColors.secondary,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: maxMs <= 0
                            ? null
                            : (v) async {
                                final target = Duration(
                                  milliseconds: (maxMs * v).round(),
                                );
                                await controller.seekTo(target);
                              },
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          VideoFormatUtils.formatDuration(position),
                          style: AppFonts.readex(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          VideoFormatUtils.formatDuration(duration),
                          style: AppFonts.readex(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RoundControlButton(
                          icon: Icons.fullscreen_rounded,
                          size: 36,
                          onTap: onFullscreen,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _RoundControlButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.52),
        ),
      ),
    );
  }
}

class _PlayerLoadingIndicator extends StatelessWidget {
  final String label;
  final bool compact;

  const _PlayerLoadingIndicator({required this.label, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: compact ? Colors.black38 : Colors.transparent,
      padding: EdgeInsets.all(compact ? 12 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLoadingIndicator(size: compact ? 28 : 36),
          if (!compact) ...[
            const SizedBox(height: 12),
            Text(
              label,
              style: AppFonts.readex(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _PlayerErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.readex(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('إعادة المحاولة', style: AppFonts.readex()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenVideoPage extends StatefulWidget {
  final String videoPath;
  final String? streamUrl;
  final Duration initialPosition;
  final bool autoPlay;

  const _FullscreenVideoPage({
    required this.videoPath,
    this.streamUrl,
    required this.initialPosition,
    required this.autoPlay,
  });

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    unawaited(_init());
  }

  Future<void> _init() async {
    final controller = MediaUrl.isRemote(widget.videoPath)
        ? VideoPlayerController.networkUrl(
            Uri.parse(widget.streamUrl ?? MediaUrl.resolve(widget.videoPath)),
          )
        : VideoPlayerController.file(File(widget.videoPath));
    try {
      await controller.initialize();
      await controller.seekTo(widget.initialPosition);
      if (widget.autoPlay) {
        await controller.play();
        await WakelockPlus.enable();
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (_) {
      await controller.dispose();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    unawaited(WakelockPlus.disable());
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_ready && _controller != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              )
            else
              const Center(child: AppLoadingIndicator(size: 40)),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.fullscreen_exit_rounded,
                  color: Colors.white,
                ),
              ),
            ),
            if (_ready && _controller != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () async {
                    final c = _controller!;
                    if (c.value.isPlaying) {
                      await c.pause();
                      await WakelockPlus.disable();
                    } else {
                      await c.play();
                      await WakelockPlus.enable();
                    }
                    setState(() {});
                  },
                  child: ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: _controller!,
                    builder: (context, value, _) {
                      return value.isPlaying
                          ? const SizedBox.shrink()
                          : Center(
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                size: 72,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const maxVideoSizeBytes = 20 * 1024 * 1024 * 1024;

Future<bool?> showAddLectureDialog(
  BuildContext context, {
  required String initialSubject,
  required String initialSection,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'إغلاق',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _AddLectureDialog(
        initialSubject: initialSubject,
        initialSection: initialSection,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

Future<bool?> showEditLectureDialog(
  BuildContext context, {
  required LectureModel lecture,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'إغلاق',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _AddLectureDialog(
        initialSubject: lecture.subject,
        initialSection: lecture.section,
        lectureToEdit: lecture,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

class _AddLectureDialog extends StatefulWidget {
  final String initialSubject;
  final String initialSection;
  final LectureModel? lectureToEdit;

  const _AddLectureDialog({
    required this.initialSubject,
    required this.initialSection,
    this.lectureToEdit,
  });

  bool get isEditing => lectureToEdit != null;

  @override
  State<_AddLectureDialog> createState() => _AddLectureDialogState();
}

class _AddLectureDialogState extends State<_AddLectureDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _imagePicker = ImagePicker();

  late String _selectedSubject;
  late String _selectedSection;
  String? _selectedTeacherId;
  File? _coverFile;
  File? _videoFile;
  String? _coverFileName;
  String? _videoFileName;
  int _videoFileSize = 0;

  UploadStatus _uploadStatus = UploadStatus.idle;
  double _uploadProgress = 0;
  String? _uploadSpeed;
  String? _uploadEta;
  String? _uploadError;
  PremiumButtonState _buttonState = PremiumButtonState.idle;

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.initialSubject;
    _selectedSection = widget.initialSection;

    final edit = widget.lectureToEdit;
    if (edit != null) {
      _titleController.text = edit.title;
      _dateController.text = edit.date;
      _selectedTeacherId = edit.teacherId;
      if (edit.coverImagePath != null) {
        _coverFileName = edit.coverImagePath!.split('/').last;
      }
      if (edit.videoPath.isNotEmpty) {
        _videoFileName = edit.videoPath.split('/').last;
        _videoFileSize = edit.fileSizeBytes;
      }
    } else {
      _dateController.text = DateTime.now().toString().substring(0, 10);
    }
    _syncTeacherSelection();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  List<UserModel> _teachersForSubject(ApiDataService data) {
    return data.getTeachersForSubject(_selectedSubject);
  }

  void _syncTeacherSelection() {
    final data = context.read<ApiDataService>();
    final auth = context.read<AuthService>();
    final teachers = _teachersForSubject(data);

    if (auth.isTeacher && auth.currentUser != null) {
      _selectedTeacherId = auth.currentUser!.id;
      return;
    }

    if (teachers.isEmpty) {
      _selectedTeacherId = null;
    } else if (_selectedTeacherId == null ||
        !teachers.any((t) => t.id == _selectedTeacherId)) {
      _selectedTeacherId = teachers.first.id;
    }
  }

  Future<void> _pickCover() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _coverFile = File(picked.path);
      _coverFileName = picked.name;
    });
  }

  Future<void> _pickVideo() async {
    final picked = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(hours: 4),
    );
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    final size = await file.length();
    if (!mounted) return;

    if (size > maxVideoSizeBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حجم الفيديو يتجاوز الحد الأقصى (${formatFileSize(maxVideoSizeBytes)})',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _videoFile = file;
      _videoFileName = picked.name;
      _videoFileSize = size;
      _uploadStatus = UploadStatus.idle;
      _uploadError = null;
    });
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_dateController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = picked.toString().substring(0, 10);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    if (!auth.canUploadLectures) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ليس لديك صلاحية رفع المحاضرات'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_videoFile == null && !widget.isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار ملف فيديو'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد أستاذ معيّن لهذه المادة'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _buttonState = PremiumButtonState.loading;
      _uploadStatus = UploadStatus.uploading;
      _uploadProgress = 0;
      _uploadError = null;
    });

    final startTime = DateTime.now();
    var lastProgress = 0.0;

    try {
      final data = context.read<ApiDataService>();
      if (widget.isEditing) {
        await data.updateLectureData(
          lectureId: widget.lectureToEdit!.id,
          title: _titleController.text.trim(),
          date: _dateController.text.trim(),
          subject: _selectedSubject,
          section: _selectedSection,
          teacherId: _selectedTeacherId!,
          videoFile: _videoFile,
          coverImageFile: _coverFile,
          onUploadProgress: _videoFile != null
              ? (progress) {
                  if (!mounted) return;
                  final elapsed = DateTime.now().difference(startTime);
                  final bytesDone = (_videoFileSize * progress).round();
                  final speed = elapsed.inMilliseconds > 0
                      ? bytesDone / (elapsed.inMilliseconds / 1000)
                      : 0.0;
                  final remainingBytes = _videoFileSize - bytesDone;
                  final etaSeconds = speed > 0
                      ? (remainingBytes / speed).round()
                      : 0;

                  setState(() {
                    _uploadProgress = progress;
                    _uploadSpeed = formatUploadSpeed(speed);
                    _uploadEta = formatEta(Duration(seconds: etaSeconds));
                  });
                  lastProgress = progress;
                }
              : null,
        );
      } else {
        await data.addLectureData(
          title: _titleController.text.trim(),
          description: '',
          subject: _selectedSubject,
          section: _selectedSection,
          teacherId: _selectedTeacherId!,
          videoFile: _videoFile!,
          coverImageFile: _coverFile,
          onUploadProgress: (progress) {
            if (!mounted) return;
            final elapsed = DateTime.now().difference(startTime);
            final bytesDone = (_videoFileSize * progress).round();
            final speed = elapsed.inMilliseconds > 0
                ? bytesDone / (elapsed.inMilliseconds / 1000)
                : 0.0;
            final remainingBytes = _videoFileSize - bytesDone;
            final etaSeconds = speed > 0 ? (remainingBytes / speed).round() : 0;

            setState(() {
              _uploadProgress = progress;
              _uploadSpeed = formatUploadSpeed(speed);
              _uploadEta = formatEta(Duration(seconds: etaSeconds));
            });
            lastProgress = progress;
          },
        );
      }

      if (!mounted) return;
      setState(() {
        _uploadProgress = 1;
        _uploadStatus = UploadStatus.success;
        _buttonState = PremiumButtonState.success;
      });

      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadStatus = UploadStatus.failure;

        _uploadError = cleanErrorMessage(e);
        _uploadProgress = lastProgress;
        _buttonState = PremiumButtonState.idle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ApiDataService>();
    final auth = context.watch<AuthService>();
    final teachers = _teachersForSubject(data);
    _syncTeacherSelection();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.94,
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          margin: const EdgeInsets.all(16),
          child: AppCard(
            padding: const EdgeInsets.all(20),
            borderRadius: AppRadius.xl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.video_call_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'تعديل المحاضرة' : 'إضافة محاضرة',
                        style: AppFonts.readex(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (_buttonState != PremiumButtonState.loading)
                      PressableScale(
                        pressedScale: 0.9,
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildField(
                            controller: _titleController,
                            label: 'عنوان المحاضرة',
                            icon: Icons.title_rounded,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: _pickDate,
                            child: AbsorbPointer(
                              child: _buildField(
                                controller: _dateController,
                                label: 'تاريخ المحاضرة',
                                icon: Icons.calendar_today_rounded,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'مطلوب' : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ReadOnlySelector(
                            label: 'المادة',
                            value: _selectedSubject,
                            icon: SubjectIcon(
                              subject: _selectedSubject,
                              size: 28,
                              showShadow: false,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ReadOnlySelector(
                            label: 'الشعبة',
                            value: _selectedSection,
                            icon: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  AppSections.letterFor(_selectedSection),
                                  style: AppFonts.readex(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (auth.isAdmin)
                            _TeacherDropdown(
                              teachers: teachers,
                              value: _selectedTeacherId,
                              onChanged: (v) =>
                                  setState(() => _selectedTeacherId = v),
                            )
                          else if (teachers.isNotEmpty)
                            _ReadOnlySelector(
                              label: 'الأستاذ',
                              value: teachers
                                  .firstWhere(
                                    (t) => t.id == _selectedTeacherId,
                                    orElse: () => teachers.first,
                                  )
                                  .name,
                              icon: const Icon(
                                Icons.person_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                          const SizedBox(height: 16),
                          _UploadTile(
                            label: 'صورة الغلاف',
                            hint: _coverFileName ?? 'اختر صورة الغلاف',
                            icon: Icons.image_rounded,
                            isSelected: _coverFile != null,
                            onTap: _pickCover,
                          ),
                          const SizedBox(height: 10),
                          _UploadTile(
                            label: 'ملف الفيديو',
                            hint:
                                _videoFileName ??
                                (widget.isEditing
                                    ? 'الفيديو الحالي (اختياري: استبدال)'
                                    : 'اختر فيديو (حد أقصى 20 GB)'),
                            subtitle: _videoFileSize > 0
                                ? formatFileSize(_videoFileSize)
                                : null,
                            icon: Icons.video_file_rounded,
                            isSelected: _videoFile != null,
                            onTap: _pickVideo,
                          ),
                          const SizedBox(height: 14),
                          UploadProgressWidget(
                            status: _uploadStatus,
                            progress: _uploadProgress,
                            fileName: _videoFileName,
                            speedLabel: _uploadSpeed,
                            etaLabel: _uploadEta,
                            errorMessage: _uploadError,
                          ),
                          const SizedBox(height: 20),
                          PremiumActionButton(
                            label: widget.isEditing
                                ? 'حفظ التعديلات'
                                : 'نشر المحاضرة',
                            loadingLabel: widget.isEditing
                                ? 'جاري الحفظ...'
                                : 'جاري الرفع...',
                            state: _buttonState,
                            onPressed:
                                _buttonState == PremiumButtonState.loading
                                ? null
                                : _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return TextFormField(
          controller: controller,
          validator: validator,
          style: AppFonts.readex(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: AppColors.icon(context)),
            filled: true,
            fillColor: isDark
                ? AppColors.overlay(0.06)
                : Colors.white.withValues(alpha: 0.85),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.secondary.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReadOnlySelector extends StatelessWidget {
  final String label;
  final String value;
  final Widget icon;

  const _ReadOnlySelector({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.overlay(0.06)
            : AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.readex(
                    fontSize: 11,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                Text(
                  value,
                  style: AppFonts.readex(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: AppColors.textSecondary(context).withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

class _TeacherDropdown extends StatelessWidget {
  final List<UserModel> teachers;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _TeacherDropdown({
    required this.teachers,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      initialValue: teachers.any((t) => t.id == value) ? value : null,
      decoration: InputDecoration(
        labelText: 'الأستاذ المعيّن',
        prefixIcon: Icon(Icons.person_rounded, color: AppColors.icon(context)),
        filled: true,
        fillColor: isDark
            ? AppColors.overlay(0.06)
            : Colors.white.withValues(alpha: 0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
      ),
      items: teachers
          .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
          .toList(),
      onChanged: teachers.isEmpty ? null : onChanged,
      validator: (v) => v == null ? 'مطلوب' : null,
    );
  }
}

class _UploadTile extends StatefulWidget {
  final String label;
  final String hint;
  final String? subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _UploadTile({
    required this.label,
    required this.hint,
    this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_UploadTile> createState() => _UploadTileState();
}

class _UploadTileState extends State<_UploadTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.12),
                      AppColors.primary.withValues(alpha: 0.06),
                    ],
                  )
                : null,
            color: widget.isSelected
                ? null
                : (isDark
                      ? AppColors.overlay(0.06)
                      : Colors.white.withValues(alpha: 0.85)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.secondary.withValues(alpha: 0.5)
                  : AppColors.border(context),
              width: widget.isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: widget.isSelected
                      ? AppColors.primaryGradient
                      : null,
                  color: widget.isSelected
                      ? null
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.isSelected ? Icons.check_rounded : widget.icon,
                  color: widget.isSelected ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: AppFonts.readex(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    Text(
                      widget.hint,
                      style: AppFonts.readex(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: widget.isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: AppFonts.readex(
                          fontSize: 11,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.upload_file_rounded,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
