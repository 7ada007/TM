import '../../core/core.dart';
import '../../theme/motion.dart';
import '../../theme/theme.dart';
import '../home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class StudentDirectoryScreen extends StatefulWidget {
  final bool showAppBar;
  final String title;

  const StudentDirectoryScreen({
    super.key,
    this.showAppBar = true,
    required this.title,
  });

  @override
  State<StudentDirectoryScreen> createState() => _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState extends State<StudentDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _genderFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() => context.read<ApiDataService>().fetchAllData();

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  List<UserModel> _resolve(UserModel? viewer, List<UserModel> students) {
    var visible = PermissionUtils.visibleStudentsFor(viewer, students);

    if (_genderFilter != null) {
      visible = visible.where((s) => s.gender == _genderFilter).toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      visible = visible.where((s) {
        return s.name.toLowerCase().contains(query) ||
            (s.section?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    visible.sort((a, b) {
      if (viewer != null) {
        if (a.id == viewer.id) return -1;
        if (b.id == viewer.id) return 1;
      }
      return a.name.compareTo(b.name);
    });

    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final viewer = context.watch<AuthService>().currentUser;
    final students = context.watch<ApiDataService>().students;
    final responsive = ResponsiveLayout.of(context);
    final showGenderFilter = PermissionUtils.seesAllGenders(viewer);
    final filtered = _resolve(viewer, students);
    final hPad = responsive.horizontalPadding;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, responsive.spacing(14), hPad, 0),
          child: AppSearchField(
            controller: _searchController,
            hintText: 'ابحث بالاسم أو الشعبة...',
            onChanged: (value) => setState(() => _searchQuery = value),
            onClear: _clearSearch,
          ),
        ),
        if (showGenderFilter)
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, responsive.spacing(12), hPad, 0),
            child: _GenderFilterBar(
              value: _genderFilter,
              onChanged: (value) => setState(() => _genderFilter = value),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            hPad,
            responsive.spacing(14),
            hPad,
            responsive.spacing(10),
          ),
          child: _DirectoryCountLabel(count: filtered.length),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: filtered.isEmpty
                ? _DirectoryEmptyState(hasQuery: _searchQuery.trim().isNotEmpty)
                : _DirectoryGrid(students: filtered, viewer: viewer),
          ),
        ),
      ],
    );

    if (!widget.showAppBar) {
      return ShellTabBody(child: content);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppTopBar(
        title: widget.title,
        showLogo: false,
        onBackTap: () => context.pop(),
      ),
      body: content,
    );
  }
}

class _GenderFilterBar extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _GenderFilterBar({required this.value, required this.onChanged});

  static const _options = [
    (value: null, label: 'الكل', icon: Icons.groups_rounded),
    (value: AppGenders.male, label: 'طلاب', icon: Icons.male_rounded),
    (value: AppGenders.female, label: 'طالبات', icon: Icons.female_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_options.length, (index) {
        final option = _options[index];
        final selected = option.value == value;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == _options.length - 1 ? 0 : 8,
            ),
            child: _GenderFilterChip(
              label: option.label,
              icon: option.icon,
              selected: selected,
              onTap: () {
                if (selected) return;
                HapticFeedback.selectionClick();
                onChanged(option.value);
              },
            ),
          ),
        );
      }),
    );
  }
}

class _GenderFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderFilterChip({
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: motionDuration(context, AppMotion.quick),
            curve: AppMotion.standardCurve,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: selected
                  ? (isDark
                        ? AppColors.darkPrimaryGradient
                        : AppColors.primaryGradient)
                  : null,
              color: selected ? null : AppColors.surface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : AppColors.border(context),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.24),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? Colors.white
                      : AppColors.textSecondary(context),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.readex(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary(context),
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
}

class _DirectoryCountLabel extends StatelessWidget {
  final int count;

  const _DirectoryCountLabel({required this.count});

  static String _label(int count) {
    if (count == 0) return 'لا نتائج';
    if (count == 1) return 'نتيجة واحدة';
    if (count == 2) return 'نتيجتان';
    if (count <= 10) return 'نتائج';
    return 'نتيجة';
  }

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
            '$count',
            style: AppFonts.readex(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.roleBadgeText(context),
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _label(count),
          style: AppFonts.readex(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}

class _DirectoryGrid extends StatelessWidget {
  final List<UserModel> students;
  final UserModel? viewer;

  const _DirectoryGrid({required this.students, required this.viewer});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveLayout.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 186).floor().clamp(2, 4);
        final extent = 196 + (responsive.textScale - 1) * 56;

        return GridView.builder(
          padding: responsive.listPadding(),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: extent,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final delay = motionDuration(
              context,
              Duration(milliseconds: 28 * (index % 12)),
            );

            return _StudentCard(
                  student: student,
                  isSelf: viewer != null && viewer!.id == student.id,
                )
                .animate()
                .fadeIn(delay: delay, duration: motionDuration(context, 280.ms))
                .slideY(
                  begin: 0.06,
                  end: 0,
                  delay: delay,
                  duration: motionDuration(context, 280.ms),
                  curve: AppMotion.enter,
                );
          },
        );
      },
    );
  }
}

class _StudentCard extends StatelessWidget {
  final UserModel student;
  final bool isSelf;

  const _StudentCard({required this.student, required this.isSelf});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final section = student.section;

    return MergeSemantics(
      child: Semantics(
        button: true,
        hint: 'عرض الملف الشخصي',
        child: PressableScale(
          onTap: () => context.push('/user/${student.id}'),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isSelf
                    ? AppColors.roleBadgeBorder(context)
                    : AppColors.border(context),
              ),
              boxShadow: AppShadows.of(brightness),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UserAvatar(
                      name: student.name,
                      photoPath: student.photoPath,
                      size: 76,
                      showBorder: false,
                      showShadow: true,
                    ),
                    if (isSelf)
                      PositionedDirectional(
                        bottom: -4,
                        start: -4,
                        child: const _SelfBadge(),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  student.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.readex(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                if (section != null && section.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Text(
                      section,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.readex(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(context),
                        height: 1.3,
                      ),
                    ),
                  )
                else
                  Text(
                    student.localizedRole,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.readex(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary(context),
                      height: 1.3,
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

class _SelfBadge extends StatelessWidget {
  const _SelfBadge();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkPrimaryGradient
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        'أنت',
        style: AppFonts.readex(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.3,
        ),
      ),
    );
  }
}

class _DirectoryEmptyState extends StatelessWidget {
  final bool hasQuery;

  const _DirectoryEmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveLayout.of(context);

    return ListView(
      padding: responsive.listPadding(),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: responsive.spacing(60)),
        Icon(
          hasQuery ? Icons.search_off_rounded : Icons.groups_outlined,
          size: 56,
          color: AppColors.textSecondary(context).withValues(alpha: 0.35),
        ),
        const SizedBox(height: 16),
        Text(
          hasQuery ? 'لا توجد نتائج' : 'لا توجد بيانات لعرضها',
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
              ? 'جرّب البحث باسم أو شعبة أخرى'
              : 'اسحب للأسفل لتحديث القائمة',
          textAlign: TextAlign.center,
          style: AppFonts.readex(
            fontSize: 13,
            height: 1.6,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}
