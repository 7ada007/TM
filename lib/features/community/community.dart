import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/core.dart';
import '../../core/chunked_uploader.dart';
import '../../theme/theme.dart';
import '../home/home.dart';
import '../lectures/lectures_widgets.dart' show PremiumVideoPlayer;

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
  final months = (diff.inDays / 30).floor();
  if (months < 12) return 'منذ $months شهر';
  return 'منذ ${(months / 12).floor()} سنة';
}

class CommunityScreen extends StatefulWidget {
  final bool showAppBar;

  const CommunityScreen({super.key, this.showAppBar = true});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<ApiDataService>().refreshCommunityPosts();
    } catch (e) {
      _error = cleanErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CommunityPostModel> _visiblePosts(
    ApiDataService data,
    UserModel? viewer,
  ) {
    final all = data.communityPosts;
    if (viewer == null || viewer.role != UserRole.student) return all;
    if (data.getAllUsers().isEmpty) return all;
    return all.where((post) {
      if (post.userId == viewer.id) return true;
      final author = data.findUserById(post.userId);
      if (author == null) return false;
      if (author.role != UserRole.student) return true;
      return author.gender == viewer.gender;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ApiDataService>();
    final viewer = context.watch<AuthService>().currentUser;
    final posts = _visiblePosts(data, viewer);

    Widget body;
    if (_loading) {
      body = const Center(child: AppLoadingIndicator());
    } else if (_error != null) {
      body = _buildErrorState(context);
    } else if (posts.isEmpty) {
      body = _buildEmptyState(context);
    } else {
      body = _buildFeed(context, posts);
    }

    final content = Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: body,
        ),
        Positioned(
          bottom: AppLayout.pageBottom,
          right: AppLayout.pageHorizontal,
          child: _buildFab(context),
        ),
      ],
    );

    if (!widget.showAppBar) {
      return ShellTabBody(child: content);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const AppTopBar(title: 'المجتمع', showLogo: false),
      body: content,
    );
  }

  Widget _buildFeed(BuildContext context, List<CommunityPostModel> posts) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.pageHorizontal,
            AppLayout.sectionGap,
            AppLayout.pageHorizontal,
            AppLayout.pageBottom + AppLayout.fabClearance,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: AppLayout.itemGap),
                child: _PostCard(post: posts[index])
                    .animate()
                    .fadeIn(delay: (40 * index).ms, duration: 260.ms)
                    .slideY(begin: 0.05, end: 0),
              ),
              childCount: posts.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.forum_rounded,
                  size: 56,
                  color: AppColors.textSecondary(
                    context,
                  ).withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد منشورات بعد',
                  style: AppFonts.readex(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'كن أول من يشارك فكرة أو سؤالاً مع المجتمع',
                  textAlign: TextAlign.center,
                  style: AppFonts.readex(
                    fontSize: 13,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: AppColors.textSecondary(
                    context,
                  ).withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppFonts.readex(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _load,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) => const _CommunityBanner();

  Widget _buildFab(BuildContext context) {
    return PressableScale(
      onTap: () => showCreatePostSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'جديد',
              style: AppFonts.readex(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityBanner extends StatelessWidget {
  const _CommunityBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0B1B36), Color(0xFF163B7C), Color(0xFF2E6FE8)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          )
        : const LinearGradient(
            colors: [Color(0xFF1740A8), Color(0xFF2E6FE8), Color(0xFF54A8F5)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          );

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppLayout.pageHorizontal,
        AppLayout.pageTop,
        AppLayout.pageHorizontal,
        0,
      ),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.42 : 0.30),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _BannerPatternPainter()),
            ),
            PositionedDirectional(
              end: -20,
              bottom: -24,
              child: Opacity(
                opacity: 0.16,
                child: Image.asset(
                  AppIcons.logoMark,
                  height: 172,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'مجتمع طريق المجد',
                          style: AppFonts.readex(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  RichText(
                    text: TextSpan(
                      style: AppFonts.readex(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      children: [
                        const TextSpan(text: 'اصنع طريقك '),
                        TextSpan(
                          text: 'للمجد',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.accent
                                : const Color(0xFFCFE8FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'شارك أفكارك، اسأل، وتعلّم مع زملائك',
                    style: AppFonts.readex(
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerPatternPainter extends CustomPainter {
  const _BannerPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(
      Offset(w * 0.86, h * 0.15),
      112,
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
    canvas.drawCircle(
      Offset(w * 0.06, h * 1.04),
      98,
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );

    final nodes = [
      Offset(w * 0.12, h * 0.30),
      Offset(w * 0.40, h * 0.15),
      Offset(w * 0.66, h * 0.29),
      Offset(w * 0.90, h * 0.52),
    ];
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = Colors.white.withValues(alpha: 0.20);
    for (int i = 0; i < nodes.length - 1; i++) {
      final a = nodes[i];
      final b = nodes[i + 1];
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final ctrl = Offset(mid.dx, mid.dy - (a - b).distance * 0.28);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      canvas.drawPath(path, line);
    }
    for (final n in nodes) {
      canvas.drawCircle(
        n,
        7,
        Paint()..color = Colors.white.withValues(alpha: 0.14),
      );
      canvas.drawCircle(
        n,
        2.6,
        Paint()..color = Colors.white.withValues(alpha: 0.78),
      );
    }

    final dot = Paint()..color = Colors.white.withValues(alpha: 0.10);
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 3; j++) {
        canvas.drawCircle(
          Offset(w * (0.60 + i * 0.095), h * (0.60 + j * 0.14)),
          1.6,
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BannerPatternPainter oldDelegate) => false;
}

void showCreatePostSheet(BuildContext context, {CommunityPostModel? editing}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CreatePostSheet(editing: editing),
  );
}

class _PostCard extends StatelessWidget {
  final CommunityPostModel post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final currentUser = auth.currentUser;
    final isAdmin = PermissionUtils.isAdmin(currentUser);
    final isOwner = currentUser?.id == post.userId;
    final canModerate = isAdmin || isOwner;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.isPinned) ...[
            Row(
              children: [
                Icon(
                  Icons.push_pin_rounded,
                  size: 14,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'منشور مثبّت',
                  style: AppFonts.readex(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              UserAvatar(
                name: post.userName,
                photoPath: post.userPhotoPath,
                size: 40,
                showShadow: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: AppFonts.readex(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    Text(
                      _timeAgo(post.createdAt),
                      style: AppFonts.readex(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  color: AppColors.textSecondary(context),
                ),
                onSelected: (value) => _handleMenuAction(context, value),
                itemBuilder: (context) => [
                  if (canModerate)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('تعديل المنشور'),
                        ],
                      ),
                    ),
                  if (isAdmin)
                    PopupMenuItem(
                      value: 'pin',
                      child: Row(
                        children: [
                          Icon(
                            post.isPinned
                                ? Icons.push_pin_outlined
                                : Icons.push_pin_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            post.isPinned ? 'إلغاء التثبيت' : 'تثبيت المنشور',
                          ),
                        ],
                      ),
                    ),
                  if (canModerate)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'حذف المنشور',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  if (!isOwner)
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('الإبلاغ عن المنشور'),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (post.title != null && post.title!.trim().isNotEmpty) ...[
            Text(
              post.title!,
              style: AppFonts.readex(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (post.content.trim().isNotEmpty)
            Text(
              post.content,
              style: AppFonts.readex(
                fontSize: 14,
                color: AppColors.textPrimary(context),
                height: 1.5,
              ),
            ),
          if (post.imagePath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onTap: () => _openImageViewer(context, post.imagePath!),
                child: Image.network(
                  MediaUrl.resolve(post.imagePath!),
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 220,
                      color: AppColors.surfaceAlt(context),
                      child: const Center(child: AppLoadingIndicator(size: 28)),
                    );
                  },
                  errorBuilder: (_, _, _) => Container(
                    height: 120,
                    color: AppColors.surfaceAlt(context),
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (post.videoPath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: PremiumVideoPlayer(videoPath: post.videoPath!),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: AppColors.border(context)),
          const SizedBox(height: 4),
          Row(
            children: [
              PressableScale(
                onTap: () => showCommentsSheet(context, post),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 19,
                      color: AppColors.textSecondary(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.commentCount > 0
                          ? '${post.commentCount} تعليق'
                          : 'تعليق',
                      style: AppFonts.readex(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openImageViewer(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(MediaUrl.resolve(path), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(BuildContext context, String action) async {
    final dataService = context.read<ApiDataService>();
    switch (action) {
      case 'edit':
        showCreatePostSheet(context, editing: post);
      case 'pin':
        try {
          await dataService.toggleCommunityPostPin(post.id);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(cleanErrorMessage(e))));
          }
        }
      case 'delete':
        _confirmDelete(context, dataService);
      case 'report':
        _showReportDialog(context, dataService);
    }
  }

  void _confirmDelete(BuildContext context, ApiDataService dataService) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المنشور نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await dataService.deleteCommunityPost(post.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف المنشور بنجاح')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(cleanErrorMessage(e))));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, ApiDataService dataService) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الإبلاغ عن المنشور'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'صف سبب الإبلاغ (اختياري)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await dataService.reportCommunityPost(
                  postId: post.id,
                  reason: reasonController.text.trim().isEmpty
                      ? null
                      : reasonController.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إرسال البلاغ، شكراً لك')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(cleanErrorMessage(e))));
                }
              }
            },
            child: const Text('إرسال البلاغ'),
          ),
        ],
      ),
    );
  }
}

void showCommentsSheet(BuildContext context, CommunityPostModel post) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CommentsSheet(post: post),
  );
}

class _CommentsSheet extends StatefulWidget {
  final CommunityPostModel post;
  const _CommentsSheet({required this.post});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  bool _loading = true;
  bool _sending = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await context.read<ApiDataService>().fetchCommunityComments(
        widget.post.id,
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await context.read<ApiDataService>().addCommunityComment(
        postId: widget.post.id,
        content: text,
      );
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(cleanErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comments = context.watch<ApiDataService>().getCommunityComments(
      widget.post.id,
    );
    final auth = context.watch<AuthService>();
    final isAdmin = PermissionUtils.isAdmin(auth.currentUser);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.75,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: AppShadows.soft(),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'التعليقات',
              style: AppFonts.readex(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: AppLoadingIndicator())
                  : comments.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد تعليقات بعد، كن أول من يعلّق',
                        style: AppFonts.readex(
                          fontSize: 13,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UserAvatar(
                                name: comment.userName,
                                photoPath: comment.userPhotoPath,
                                size: 32,
                                showShadow: false,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceAlt(context),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.userName,
                                        style: AppFonts.readex(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        comment.content,
                                        style: AppFonts.readex(
                                          fontSize: 13,
                                          color: AppColors.textPrimary(context),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isAdmin)
                                IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.textSecondary(context),
                                  ),
                                  onPressed: () => context
                                      .read<ApiDataService>()
                                      .deleteCommunityComment(
                                        postId: widget.post.id,
                                        commentId: comment.id,
                                      ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'أضف تعليقاً...',
                          filled: true,
                          fillColor: AppColors.surfaceAlt(context),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PressableScale(
                      onTap: _send,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: AppLoadingIndicator(
                                  size: 20,
                                  color: Colors.white,
                                ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  final CommunityPostModel? editing;
  const _CreatePostSheet({this.editing});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  File? _pickedVideo;
  VideoPlayerController? _videoController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isPublishing = false;
  double _uploadProgress = 0;

  bool _existingMediaRemoved = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _titleController.text = editing.title ?? '';
      _contentController.text = editing.content;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedImage = File(image.path);
          _pickedVideo = null;
          _videoController?.dispose();
          _videoController = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (video == null) return;
      final file = File(video.path);
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      if (controller.value.duration > const Duration(minutes: 2)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الحد الأقصى لمدة الفيديو هو دقيقتان'),
            ),
          );
        }
        controller.dispose();
        return;
      }
      setState(() {
        _pickedVideo = file;
        _pickedImage = null;
        _videoController?.dispose();
        _videoController = controller;
        _videoController!.play();
        _videoController!.setLooping(true);
      });
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  Future<void> _publish() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _pickedImage == null && _pickedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء كتابة نص أو اختيار وسائط')),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
      _uploadProgress = 0;
    });

    try {
      final dataService = context.read<ApiDataService>();
      String? imagePath = (_isEditing && !_existingMediaRemoved)
          ? widget.editing!.imagePath
          : null;
      String? videoPath = (_isEditing && !_existingMediaRemoved)
          ? widget.editing!.videoPath
          : null;

      if (_pickedImage != null) {
        imagePath = await ChunkedUploader.upload(
          _pickedImage!,
          onProgress: (p) =>
              mounted ? setState(() => _uploadProgress = p) : null,
        );
        videoPath = null;
      } else if (_pickedVideo != null) {
        videoPath = await ChunkedUploader.upload(
          _pickedVideo!,
          onProgress: (p) =>
              mounted ? setState(() => _uploadProgress = p) : null,
        );
        imagePath = null;
      }

      final title = _titleController.text.trim();

      if (_isEditing) {
        final editing = widget.editing!;
        editing.title = title.isEmpty ? null : title;
        editing.content = content;
        editing.imagePath = imagePath;
        editing.videoPath = videoPath;
        await dataService.updateCommunityPost(editing);
      } else {
        await dataService.createCommunityPost(
          title: title.isEmpty ? null : title,
          content: content,
          imagePath: imagePath,
          videoPath: videoPath,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'تم تعديل المنشور بنجاح' : 'تم نشر المنشور بنجاح',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(cleanErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  bool get _hasImage =>
      _pickedImage != null ||
      (_isEditing &&
          !_existingMediaRemoved &&
          widget.editing!.imagePath != null);

  bool get _hasVideo =>
      _pickedVideo != null ||
      (_isEditing &&
          !_existingMediaRemoved &&
          widget.editing!.videoPath != null);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;
    final hasImage = _hasImage;
    final hasVideo = _hasVideo;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: AppShadows.soft(),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isEditing ? 'تعديل المنشور' : 'إنشاء منشور جديد',
                style: AppFonts.readex(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'عنوان المنشور (اختياري)',
                  filled: true,
                  fillColor: AppColors.surfaceAlt(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'ماذا تريد أن تشارك مع المجتمع؟',
                  filled: true,
                  fillColor: AppColors.surfaceAlt(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_pickedImage != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _pickedImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => setState(() => _pickedImage = null),
                    ),
                  ],
                )
              else if (_isEditing &&
                  !_existingMediaRemoved &&
                  widget.editing!.imagePath != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        MediaUrl.resolve(widget.editing!.imagePath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          setState(() => _existingMediaRemoved = true),
                    ),
                  ],
                ),
              if (_pickedVideo != null && _videoController != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => setState(() {
                        _pickedVideo = null;
                        _videoController?.dispose();
                        _videoController = null;
                      }),
                    ),
                  ],
                )
              else if (_isEditing &&
                  !_existingMediaRemoved &&
                  widget.editing!.videoPath != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: PremiumVideoPlayer(
                          videoPath: widget.editing!.videoPath!,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          setState(() => _existingMediaRemoved = true),
                    ),
                  ],
                ),
              if (_pickedImage != null || _pickedVideo != null)
                const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Row(
                  key: ValueKey('media_${hasImage}_$hasVideo'),
                  children: [
                    if (!hasVideo)
                      _buildMediaButton(
                        context,
                        icon: Icons.image_rounded,
                        label: hasImage ? 'تغيير الصورة' : 'صورة',
                        onTap: _pickImage,
                      ),
                    if (!hasImage && !hasVideo) const SizedBox(width: 12),
                    if (!hasImage)
                      _buildMediaButton(
                        context,
                        icon: Icons.videocam_rounded,
                        label: hasVideo ? 'تغيير الفيديو' : 'فيديو',
                        onTap: _pickVideo,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_isPublishing && _uploadProgress > 0) ...[
                LinearProgressIndicator(
                  value: _uploadProgress,
                  color: AppColors.primary,
                  backgroundColor: AppColors.surfaceAlt(context),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _isPublishing ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isPublishing
                    ? const AppLoadingIndicator(size: 24, color: Colors.white)
                    : Text(
                        _isEditing ? 'حفظ التعديلات' : 'نشر سؤال أو فكرة',
                        style: AppFonts.readex(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: PressableScale(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.icon(context), size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppFonts.readex(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
