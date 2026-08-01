import '../../core/core.dart';
import '../../theme/theme.dart';
import '../classmates/classmates.dart';
import '../community/community.dart';
import '../home/home.dart';
import '../lectures/lectures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return AppShellScaffold(
      tabTitles: const ['الرئيسية', 'المحاضرات', 'الطلاب', 'المجتمع'],
      pages: [
        const TeacherHomeTab(),
        LecturesScreen(
          showUploadFab: auth.canUploadLectures,
          showAppBar: false,
        ),
        const StudentDirectoryScreen(showAppBar: false, title: 'الطلاب'),
        const CommunityScreen(showAppBar: false),
      ],
      navItems: const [
        PremiumNavItem(iconKind: AppIconKind.home, label: 'الرئيسية'),
        PremiumNavItem(iconKind: AppIconKind.lectures, label: 'المحاضرات'),
        PremiumNavItem(iconKind: AppIconKind.students, label: 'الطلاب'),
        PremiumNavItem(iconKind: AppIconKind.community, label: 'المجتمع'),
      ],
    );
  }
}

class TeacherHomeTab extends StatelessWidget {
  const TeacherHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<ApiDataService>();
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final subjects = data.getSubjectsForTeacher(user.id);
    final myLectures = data.getLecturesForTeacher(user.id)
      ..sort(
        (a, b) => (b.publishedAt ?? b.date).compareTo(a.publishedAt ?? a.date),
      );
    final recent = myLectures.take(3).toList();
    final canUpload = auth.canUploadLectures;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: AppLayout.pagePaddingOf(context),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              HomeGreetingHeader(
                name: user.name,
                subtitle: canUpload
                    ? 'لديك صلاحية رفع المحاضرات، شارك علمك مع طلابك'
                    : 'تابع محاضراتك وتواصل مع طلابك',
                badge: HomeHeaderBadge(
                  icon: canUpload
                      ? Icons.cloud_upload_rounded
                      : Icons.menu_book_rounded,
                  label: canUpload ? 'صلاحية الرفع مفعّلة' : 'أستاذ',
                ),
                trailing: UserAvatar(
                  name: user.name,
                  photoPath: user.photoPath,
                  size: 58,
                  showShadow: false,
                ),
              ).animate().fadeIn(duration: 340.ms).slideY(begin: 0.04, end: 0),
              const SizedBox(height: AppLayout.blockGap),
              Row(
                children: [
                  Expanded(
                    child: HomeStatTile(
                      iconKind: AppIconKind.lectures,
                      label: 'محاضراتي',
                      value: '${myLectures.length}',
                      color: AppColors.primary,
                      onTap: () => ShellTabs.of(context)?.select(1),
                    ),
                  ),
                  const SizedBox(width: AppLayout.itemGap),
                  Expanded(
                    child: HomeStatTile(
                      icon: Icons.menu_book_rounded,
                      label: 'موادي',
                      value: '${subjects.length}',
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 60.ms, duration: 340.ms),
              const SizedBox(height: AppLayout.sectionGap),
              const HomeSectionTitle(title: 'إجراءات سريعة'),
              HomeActionCard(
                icon: Icons.fact_check_rounded,
                title: 'الحضور والغياب',
                subtitle: 'تسجيل ومتابعة حضور الطلاب',
                onTap: () => context.push('/admin/attendance'),
              ).animate().fadeIn(delay: 100.ms, duration: 320.ms),
              const SizedBox(height: AppLayout.itemGap),
              HomeActionCard(
                icon: Icons.podcasts_rounded,
                title: 'المتابعة المباشرة',
                subtitle: 'من المتصل الآن وأي محاضرة يشاهد',
                color: AppColors.warning_(context),
                onTap: () => context.push('/admin/monitoring'),
              ).animate().fadeIn(delay: 120.ms, duration: 320.ms),
              const SizedBox(height: AppLayout.itemGap),
              HomeActionCard(
                icon: Icons.video_library_rounded,
                title: 'المحاضرات',
                subtitle: canUpload
                    ? 'إدارة محاضراتك ورفع محاضرة جديدة'
                    : 'استعراض محاضرات المعهد',
                color: AppColors.secondary,
                onTap: () => ShellTabs.of(context)?.select(1),
              ).animate().fadeIn(delay: 140.ms, duration: 320.ms),
              const SizedBox(height: AppLayout.sectionGap),
              const HomeSectionTitle(title: 'موادي الدراسية'),
              if (subjects.isEmpty)
                AppCard(
                  margin: EdgeInsets.zero,
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: AppColors.textSecondary(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'لم تُعيَّن لأي مادة بعد',
                          style: AppFonts.readex(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...subjects.asMap().entries.map(
                  (entry) =>
                      AppCard(
                            margin: const EdgeInsets.only(
                              bottom: AppLayout.itemGap,
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                SubjectIcon(subject: entry.value, size: 44),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: AppFonts.readex(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.roleBadgeBg(context),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${data.getLectureCountsBySubject(subjects: [entry.value])[entry.value] ?? 0} محاضرة',
                                    style: AppFonts.readex(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.roleBadgeText(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(
                            delay: (180 + 50 * entry.key).ms,
                            duration: 300.ms,
                          )
                          .slideY(begin: 0.05, end: 0),
                ),
              if (recent.isNotEmpty) ...[
                const SizedBox(height: AppLayout.blockGap),
                HomeSectionTitle(
                  title: 'أحدث محاضراتي',
                  actionLabel: 'عرض الكل',
                  onAction: () => ShellTabs.of(context)?.select(1),
                ),
                ...recent.asMap().entries.map(
                  (e) => HomeLectureTile(lecture: e.value)
                      .animate()
                      .fadeIn(delay: (220 + 60 * e.key).ms, duration: 300.ms)
                      .slideY(begin: 0.05, end: 0),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}
