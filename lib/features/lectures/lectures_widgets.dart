import '../../core/core.dart';
import '../../theme/motion.dart';
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

export 'media_player.dart' show PremiumVideoPlayer;

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

class PremiumLectureCard extends StatelessWidget {
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

  void _openDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    context.push('/lecture/${lecture.id}');
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = prefersReducedMotion(context);
    final delay = reduceMotion
        ? Duration.zero
        : Duration(milliseconds: 45 * (animationIndex % 8));

    final card = Selector<ApiDataService, ({double avg, int count, bool fav})>(
      selector: (_, data) => (
        avg: data.getAverageRating(lecture.id),
        count: data.getRatingCount(lecture.id),
        fav: data.findLectureById(lecture.id)?.isFavorite ?? lecture.isFavorite,
      ),
      builder: (context, state, _) {
        return MergeSemantics(
          child: Semantics(
            button: true,
            hint: 'فتح المحاضرة',
            child: PressableScale(
              pressedScale: 0.98,
              onTap: () => _openDetail(context),
              child: AppCard(
                margin: const EdgeInsets.only(bottom: AppLayout.cardGap),
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LectureCover(
                      lecture: lecture,
                      showManageMenu: showManageMenu,
                      onManageChanged: onManageChanged,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                                    height: 1.4,
                                    color: AppColors.textPrimary(context),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (showFavorite) ...[
                                const SizedBox(width: 8),
                                _FavoriteButton(
                                  lectureId: lecture.id,
                                  isFavorite: state.fav,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          _LectureTeacherRow(lecture: lecture),
                          const SizedBox(height: 12),
                          _LectureMetaRow(
                            lecture: lecture,
                            average: state.avg,
                            ratingCount: state.count,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (reduceMotion) return card;

    return card
        .animate()
        .fadeIn(delay: delay, duration: 300.ms)
        .slideY(begin: 0.05, end: 0, delay: delay, curve: AppMotion.enter);
  }
}

class _LectureCover extends StatelessWidget {
  final LectureModel lecture;
  final bool showManageMenu;
  final VoidCallback? onManageChanged;

  const _LectureCover({
    required this.lecture,
    required this.showManageMenu,
    required this.onManageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppSubjects.gradientFor(lecture.subject);
    final coverPath = lecture.coverImagePath;
    final isRemote = MediaUrl.isRemote(coverPath);
    final hasCover =
        coverPath != null &&
        coverPath.isNotEmpty &&
        (isRemote || File(coverPath).existsSync());
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (MediaQuery.sizeOf(context).width * dpr).round().clamp(
      360,
      1440,
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors.map((c) => c.withValues(alpha: 0.9)).toList(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: AppSubjects.bannerAssetFor(lecture.subject) != null
                  ? Image.asset(
                      AppSubjects.bannerAssetFor(lecture.subject)!,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      color: Colors.black.withValues(alpha: 0.3),
                      colorBlendMode: BlendMode.darken,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    )
                  : null,
            ),
            if (hasCover)
              isRemote
                  ? Image.network(
                      MediaUrl.resolve(coverPath),
                      fit: BoxFit.cover,
                      cacheWidth: cacheWidth,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                      frameBuilder: (context, child, frame, wasSync) {
                        if (wasSync) return child;
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: motionDuration(context, AppMotion.standard),
                          curve: AppMotion.standardCurve,
                          child: child,
                        );
                      },
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    )
                  : Image.file(
                      File(coverPath),
                      fit: BoxFit.cover,
                      cacheWidth: cacheWidth,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
            PositionedDirectional(
              start: 12,
              top: 12,
              child: SubjectIcon(subject: lecture.subject, size: 36),
            ),
            if (showManageMenu)
              PositionedDirectional(
                end: 10,
                top: 10,
                child: GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: LectureManageMenu(
                    lecture: lecture,
                    onChanged: onManageChanged,
                  ),
                ),
              ),
            const Center(child: _PlayGlyph()),
            PositionedDirectional(
              start: 12,
              bottom: 12,
              child: Row(
                children: [
                  _CoverPill(text: lecture.section),
                  if (lecture.duration != null &&
                      lecture.duration!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _CoverPill(
                      text: lecture.duration!,
                      icon: Icons.schedule_rounded,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayGlyph extends StatelessWidget {
  const _PlayGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 32,
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

class _CoverPill extends StatelessWidget {
  final String text;
  final IconData? icon;

  const _CoverPill({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppFonts.readex(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final String lectureId;
  final bool isFavorite;

  const _FavoriteButton({required this.lectureId, required this.isFavorite});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.read<ApiDataService>().toggleLectureFavorite(lectureId);
          },
          child: SizedBox(
            width: 40,
            height: 40,
            child: AnimatedSwitcher(
              duration: motionDuration(context, AppMotion.quick),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(isFavorite),
                color: isFavorite
                    ? AppColors.error_(context)
                    : AppColors.textSecondary(context),
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LectureTeacherRow extends StatelessWidget {
  final LectureModel lecture;

  const _LectureTeacherRow({required this.lecture});

  @override
  Widget build(BuildContext context) {
    final teacher = context.select<ApiDataService, UserModel?>(
      (data) => data.findUserById(lecture.teacherId),
    );
    final name = lecture.teacherName.trim().isNotEmpty
        ? lecture.teacherName
        : (teacher?.name ?? 'غير محدّد');

    return Row(
      children: [
        UserAvatar(
          name: name,
          photoPath: teacher?.photoPath,
          size: 26,
          showBorder: false,
          showShadow: false,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.readex(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AppColors.textSecondary(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _LectureMetaRow extends StatelessWidget {
  final LectureModel lecture;
  final double average;
  final int ratingCount;

  const _LectureMetaRow({
    required this.lecture,
    required this.average,
    required this.ratingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today_rounded,
          size: 13,
          color: AppColors.textSecondary(context),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            lecture.date,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.readex(
              fontSize: 12,
              height: 1.3,
              color: AppColors.textSecondary(context),
            ),
          ),
        ),
        if (ratingCount > 0) ...[
          const SizedBox(width: 10),
          LectureRatingBadge(average: average, count: ratingCount),
        ],
      ],
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
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.enabled
          ? () => setState(() => _pressed = false)
          : null,
      onTap: widget.enabled ? widget.onTap : null,
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

class StudentLecturesHeader extends StatelessWidget {
  final String section;
  final int subjectCount;
  final int lectureCount;

  const StudentLecturesHeader({
    super.key,
    required this.section,
    required this.subjectCount,
    required this.lectureCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'محاضراتي',
                style: AppFonts.readex(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'اختر مادة لعرض محاضراتها',
                style: AppFonts.readex(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeaderPill(icon: Icons.class_rounded, label: section),
                  _HeaderPill(
                    icon: Icons.menu_book_rounded,
                    label: '$subjectCount مادة',
                  ),
                  _HeaderPill(
                    icon: Icons.play_circle_outline_rounded,
                    label: LectureCopy.countLabel(lectureCount),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.roleBadgeBg(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.roleBadgeBorder(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.roleBadgeText(context)),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppFonts.readex(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: AppColors.roleBadgeText(context),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentSubjectGrid extends StatelessWidget {
  final List<String> subjects;
  final Map<String, int> lectureCounts;
  final ValueChanged<String> onSubjectTap;
  final Future<void> Function()? onRefresh;

  const StudentSubjectGrid({
    super.key,
    required this.subjects,
    required this.lectureCounts,
    required this.onSubjectTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveLayout.of(context);

    final grid = LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 200).floor().clamp(2, 4);
        final tileWidth =
            (constraints.maxWidth -
                responsive.horizontalPadding * 2 -
                AppLayout.itemGap * (columns - 1)) /
            columns;
        final extent = (tileWidth * 1.12).clamp(150.0, 210.0);

        return GridView.builder(
          padding: responsive.listPadding(),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppLayout.itemGap,
            crossAxisSpacing: AppLayout.itemGap,
            mainAxisExtent: extent,
          ),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];
            return _SubjectCard(
              subject: subject,
              lectureCount: lectureCounts[subject] ?? 0,
              animationIndex: index,
              onTap: () {
                HapticFeedback.selectionClick();
                onSubjectTap(subject);
              },
            );
          },
        );
      },
    );

    if (onRefresh == null) return grid;

    return RefreshIndicator(
      onRefresh: onRefresh!,
      color: AppColors.primary,
      child: grid,
    );
  }
}

class _SubjectCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = AppSubjects.gradientFor(subject);
    final banner = AppSubjects.bannerAssetFor(subject);
    final reduceMotion = prefersReducedMotion(context);
    final delay = reduceMotion
        ? Duration.zero
        : Duration(milliseconds: 40 * (animationIndex % 8));

    final card = MergeSemantics(
      child: Semantics(
        button: true,
        label: subject,
        value: LectureCopy.countLabel(lectureCount),
        child: PressableScale(
          pressedScale: 0.96,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
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
                      filterQuality: FilterQuality.medium,
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
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                        stops: const [0.35, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SubjectIcon(subject: subject, size: 40),
                        const Spacer(),
                        Text(
                          subject,
                          style: AppFonts.readex(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.play_circle_outline_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        LectureCopy.countLabel(lectureCount),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppFonts.readex(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                color: Colors.white,
                                size: 20,
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
        ),
      ),
    );

    if (reduceMotion) return card;

    return card
        .animate()
        .fadeIn(delay: delay, duration: 300.ms)
        .slideY(begin: 0.06, end: 0, delay: delay, curve: AppMotion.enter);
  }
}

abstract final class LectureCopy {
  static String countLabel(int count) {
    if (count == 0) return 'لا محاضرات';
    if (count == 1) return 'محاضرة واحدة';
    if (count == 2) return 'محاضرتان';
    if (count <= 10) return '$count محاضرات';
    return '$count محاضرة';
  }
}

enum LectureSort { newest, oldest, topRated }

extension on LectureSort {
  String get label => switch (this) {
    LectureSort.newest => 'الأحدث',
    LectureSort.oldest => 'الأقدم',
    LectureSort.topRated => 'الأعلى تقييماً',
  };

  IconData get icon => switch (this) {
    LectureSort.newest => Icons.schedule_rounded,
    LectureSort.oldest => Icons.history_rounded,
    LectureSort.topRated => Icons.star_rounded,
  };
}

class StudentLectureList extends StatefulWidget {
  final String subject;
  final List<LectureModel> lectures;
  final VoidCallback onBack;

  const StudentLectureList({
    super.key,
    required this.subject,
    required this.lectures,
    required this.onBack,
  });

  @override
  State<StudentLectureList> createState() => _StudentLectureListState();
}

class _StudentLectureListState extends State<StudentLectureList> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  LectureSort _sort = LectureSort.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  Future<void> _refresh() => AppRefresh.reload(context);

  DateTime _sortKey(LectureModel lecture) {
    return DateTime.tryParse(lecture.publishedAt ?? '') ??
        DateTime.tryParse(lecture.date) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<LectureModel> _resolve(ApiDataService data) {
    var list = List<LectureModel>.from(widget.lectures);

    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((l) {
        return l.title.toLowerCase().contains(query) ||
            l.teacherName.toLowerCase().contains(query) ||
            l.description.toLowerCase().contains(query);
      }).toList();
    }

    switch (_sort) {
      case LectureSort.newest:
        list.sort((a, b) => _sortKey(b).compareTo(_sortKey(a)));
      case LectureSort.oldest:
        list.sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));
      case LectureSort.topRated:
        list.sort((a, b) {
          final byRating = data
              .getAverageRating(b.id)
              .compareTo(data.getAverageRating(a.id));
          if (byRating != 0) return byRating;
          return _sortKey(b).compareTo(_sortKey(a));
        });
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ApiDataService>();
    final responsive = ResponsiveLayout.of(context);
    final hPad = responsive.horizontalPadding;
    final visible = _resolve(data);
    final hasQuery = _query.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, responsive.spacing(14), hPad, 0),
          child: _LectureListHeader(
            subject: widget.subject,
            count: widget.lectures.length,
            onBack: widget.onBack,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, responsive.spacing(14), hPad, 0),
          child: AppSearchField(
            controller: _searchController,
            hintText: 'ابحث في المحاضرات...',
            onChanged: (value) => setState(() => _query = value),
            onClear: _clearSearch,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            hPad,
            responsive.spacing(12),
            hPad,
            responsive.spacing(12),
          ),
          child: _LectureSortBar(
            value: _sort,
            resultCount: visible.length,
            onChanged: (value) => setState(() => _sort = value),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: visible.isEmpty
                ? _LectureEmptyState(hasQuery: hasQuery)
                : ListView.builder(
                    padding: responsive.listPadding(),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      return PremiumLectureCard(
                        key: ValueKey(visible[index].id),
                        lecture: visible[index],
                        animationIndex: index,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _LectureListHeader extends StatelessWidget {
  final String subject;
  final int count;
  final VoidCallback onBack;

  const _LectureListHeader({
    required this.subject,
    required this.count,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppSubjects.gradientFor(subject);

    return Row(
      children: [
        Semantics(
          button: true,
          label: 'رجوع إلى المواد',
          child: PressableScale(
            pressedScale: 0.9,
            onTap: onBack,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppColors.overlay(0.10) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(context)),
                boxShadow: AppShadows.of(Theme.of(context).brightness),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.icon(context),
                size: 17,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SubjectIcon(subject: subject, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.readex(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: isDark ? AppColors.accent : colors.first,
                ),
              ),
              Text(
                LectureCopy.countLabel(count),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.readex(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LectureSortBar extends StatelessWidget {
  final LectureSort value;
  final int resultCount;
  final ValueChanged<LectureSort> onChanged;

  const _LectureSortBar({
    required this.value,
    required this.resultCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.roleBadgeBg(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.roleBadgeBorder(context)),
          ),
          child: Text(
            '$resultCount',
            style: AppFonts.readex(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: AppColors.roleBadgeText(context),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                for (final option in LectureSort.values) ...[
                  _SortChip(
                    label: option.label,
                    icon: option.icon,
                    selected: option == value,
                    onTap: () {
                      if (option == value) return;
                      HapticFeedback.selectionClick();
                      onChanged(option);
                    },
                  ),
                  if (option != LectureSort.values.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: motionDuration(context, AppMotion.quick),
            curve: AppMotion.standardCurve,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: selected
                  ? (isDark
                        ? AppColors.darkPrimaryGradient
                        : AppColors.primaryGradient)
                  : null,
              color: selected ? null : AppColors.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : AppColors.border(context),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? Colors.white
                      : AppColors.textSecondary(context),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppFonts.readex(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    height: 1.3,
                    color: selected
                        ? Colors.white
                        : AppColors.textSecondary(context),
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

class _LectureEmptyState extends StatelessWidget {
  final bool hasQuery;

  const _LectureEmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveLayout.of(context);

    return ListView(
      padding: responsive.listPadding(),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: responsive.spacing(48)),
        Icon(
          hasQuery ? Icons.search_off_rounded : Icons.video_library_outlined,
          size: 56,
          color: AppColors.icon(context).withValues(alpha: 0.28),
        ),
        const SizedBox(height: 16),
        Text(
          hasQuery ? 'لا توجد نتائج' : 'لا توجد محاضرات في هذه المادة',
          textAlign: TextAlign.center,
          style: AppFonts.readex(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hasQuery
              ? 'جرّب كلمة بحث أخرى أو اسم أستاذ'
              : 'سيتم إشعارك عند نشر محاضرات جديدة',
          textAlign: TextAlign.center,
          style: AppFonts.readex(
            fontSize: 13,
            height: 1.7,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
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
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
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
