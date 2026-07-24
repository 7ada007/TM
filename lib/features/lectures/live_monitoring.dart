import 'dart:async';
import '../../core/core.dart';
import '../../theme/motion.dart';
import '../../theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

enum WatchStatus { watching, paused, completed, online, offline }

extension WatchStatusView on WatchStatus {
  String get label => switch (this) {
    WatchStatus.watching => 'يشاهد',
    WatchStatus.paused => 'متوقف مؤقتاً',
    WatchStatus.completed => 'أكمل',
    WatchStatus.online => 'متصل',
    WatchStatus.offline => 'غير متصل',
  };

  IconData get icon => switch (this) {
    WatchStatus.watching => Icons.play_arrow_rounded,
    WatchStatus.paused => Icons.pause_rounded,
    WatchStatus.completed => Icons.verified_rounded,
    WatchStatus.online => Icons.wifi_tethering_rounded,
    WatchStatus.offline => Icons.cloud_off_rounded,
  };

  Color color(BuildContext context) => switch (this) {
    WatchStatus.watching => const Color(0xFF22C55E),
    WatchStatus.paused => AppColors.warning_(context),
    WatchStatus.completed => AppColors.success_(context),
    WatchStatus.online => AppColors.info_(context),
    WatchStatus.offline => AppColors.textSecondary(context),
  };
}

enum MonitorGrouping { students, lectures }

enum MonitorSort { activity, viewers, percent, watched, name }

extension on MonitorSort {
  String get label => switch (this) {
    MonitorSort.activity => 'آخر نشاط',
    MonitorSort.viewers => 'الأكثر مشاهدة',
    MonitorSort.percent => 'نسبة الإكمال',
    MonitorSort.watched => 'وقت المشاهدة',
    MonitorSort.name => 'الاسم',
  };

  IconData get icon => switch (this) {
    MonitorSort.activity => Icons.bolt_rounded,
    MonitorSort.viewers => Icons.groups_rounded,
    MonitorSort.percent => Icons.percent_rounded,
    MonitorSort.watched => Icons.timelapse_rounded,
    MonitorSort.name => Icons.sort_by_alpha_rounded,
  };
}

class MonitorEntry {
  final String userId;
  final String userName;
  final String section;
  final String? photoPath;
  final ViewerState? live;
  final LectureProgressRecord? stored;
  final LectureModel? lecture;

  const MonitorEntry({
    required this.userId,
    required this.userName,
    required this.section,
    this.photoPath,
    this.live,
    this.stored,
    this.lecture,
  });

  bool get online => live?.online ?? false;
  bool get isWatching => live?.isWatching ?? false;
  bool get playing => live?.playing ?? false;

  bool get completed => live?.completed ?? stored?.completed ?? false;

  double get positionSeconds =>
      live?.positionSeconds ?? stored?.lastPositionSeconds ?? 0;

  double get durationSeconds => (live?.durationSeconds ?? 0) > 0
      ? live!.durationSeconds
      : (stored?.durationSeconds ?? 0);

  double get watchedSeconds =>
      live?.watchedSeconds ?? stored?.watchedSeconds ?? 0;

  double get percent {
    final p = live?.percent ?? stored?.percent ?? 0;
    return p.clamp(0.0, 1.0);
  }

  DateTime? get lastActivity => live?.lastSeenAt ?? stored?.updatedAt;

  String? get lectureId => live?.lectureId ?? stored?.lectureId;

  String get lectureTitle =>
      live?.lectureTitle ?? lecture?.title ?? 'محاضرة غير معروفة';

  String get lectureSubject => live?.lectureSubject ?? lecture?.subject ?? '';

  String get teacherName => lecture?.teacherName ?? '';

  WatchStatus get status {
    if (isWatching) return playing ? WatchStatus.watching : WatchStatus.paused;
    if (completed) return WatchStatus.completed;
    if (online) return WatchStatus.online;
    return WatchStatus.offline;
  }
}

class LectureGroup {
  final String lectureId;
  final String title;
  final String subject;
  final String teacherName;
  final List<MonitorEntry> entries;

  const LectureGroup({
    required this.lectureId,
    required this.title,
    required this.subject,
    required this.teacherName,
    required this.entries,
  });

  int get activeViewers => entries.where((e) => e.isWatching).length;
  int get completedCount => entries.where((e) => e.completed).length;

  double get averagePercent {
    if (entries.isEmpty) return 0;
    final total = entries.fold<double>(0, (sum, e) => sum + e.percent);
    return total / entries.length;
  }

  DateTime? get lastActivity {
    DateTime? latest;
    for (final e in entries) {
      final at = e.lastActivity;
      if (at == null) continue;
      if (latest == null || at.isAfter(latest)) latest = at;
    }
    return latest;
  }
}

abstract final class MonitorFormat {
  static String clock(double seconds) {
    if (seconds <= 0) return '00:00';
    return VideoFormatUtils.formatDuration(Duration(seconds: seconds.round()));
  }

  static String percent(double value) => '${(value * 100).round()}٪';

  static String relative(DateTime? time) {
    if (time == null) return 'لا يوجد نشاط';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 10) return 'الآن';
    if (diff.inSeconds < 60) return 'قبل ${diff.inSeconds} ثانية';
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'قبل ${diff.inHours} ساعة';
    return 'قبل ${diff.inDays} يوم';
  }

  static String exact(DateTime? time) {
    if (time == null) return '—';
    final now = DateTime.now();
    final sameDay =
        time.year == now.year && time.month == now.month && time.day == now.day;
    return DateFormat(
      sameDay ? 'h:mm:ss a' : 'd MMM h:mm a',
      'ar',
    ).format(time);
  }
}

class LiveMonitoringView extends StatefulWidget {
  const LiveMonitoringView({super.key});

  @override
  State<LiveMonitoringView> createState() => _LiveMonitoringViewState();
}

class _LiveMonitoringViewState extends State<LiveMonitoringView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  MonitorGrouping _grouping = MonitorGrouping.students;
  MonitorSort _sort = MonitorSort.activity;
  WatchStatus? _statusFilter;
  String? _subjectFilter;
  String? _sectionFilter;
  String? _teacherFilter;

  List<LectureProgressRecord> _stored = const [];
  bool _loadingStored = true;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _loadStored();
    _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStored() async {
    try {
      final rows = await context.read<RealtimeService>().fetchProgress();
      if (!mounted) return;
      setState(() {
        _stored = rows;
        _loadingStored = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStored = false);
    }
  }

  Future<void> _refresh() => AppRefresh.reload(context, also: _loadStored);

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  bool get _hasActiveFilters =>
      _statusFilter != null ||
      _subjectFilter != null ||
      _sectionFilter != null ||
      _teacherFilter != null;

  void _resetFilters() {
    setState(() {
      _statusFilter = null;
      _subjectFilter = null;
      _sectionFilter = null;
      _teacherFilter = null;
    });
  }

  List<MonitorEntry> _buildEntries(
    ApiDataService data,
    RealtimeService realtime,
    UserModel? viewer,
  ) {
    final students = PermissionUtils.visibleStudentsFor(viewer, data.students);
    final storedByUser = <String, LectureProgressRecord>{};
    for (final row in _stored) {
      final existing = storedByUser[row.userId];
      final rowAt = row.updatedAt;
      final existingAt = existing?.updatedAt;
      if (existing == null ||
          (rowAt != null &&
              (existingAt == null || rowAt.isAfter(existingAt)))) {
        storedByUser[row.userId] = row;
      }
    }

    final seen = <String>{};
    final entries = <MonitorEntry>[];

    for (final student in students) {
      seen.add(student.id);
      final live = realtime.viewerFor(student.id);
      final stored = storedByUser[student.id];
      final lectureId = live?.lectureId ?? stored?.lectureId;
      entries.add(
        MonitorEntry(
          userId: student.id,
          userName: student.name,
          section: student.section ?? '',
          photoPath: student.photoPath,
          live: live,
          stored: stored,
          lecture: lectureId == null ? null : data.findLectureById(lectureId),
        ),
      );
    }

    for (final live in realtime.viewers) {
      if (seen.contains(live.userId)) continue;
      seen.add(live.userId);
      final stored = storedByUser[live.userId];
      final lectureId = live.lectureId ?? stored?.lectureId;
      entries.add(
        MonitorEntry(
          userId: live.userId,
          userName: live.userName,
          section: live.section,
          photoPath: data.findUserById(live.userId)?.photoPath,
          live: live,
          stored: stored,
          lecture: lectureId == null ? null : data.findLectureById(lectureId),
        ),
      );
    }

    return entries;
  }

  bool _matches(MonitorEntry e) {
    if (_statusFilter != null && e.status != _statusFilter) return false;
    if (_subjectFilter != null && e.lectureSubject != _subjectFilter) {
      return false;
    }
    if (_sectionFilter != null && e.section != _sectionFilter) return false;
    if (_teacherFilter != null && e.teacherName != _teacherFilter) return false;

    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return e.userName.toLowerCase().contains(query) ||
        e.section.toLowerCase().contains(query) ||
        e.lectureTitle.toLowerCase().contains(query) ||
        e.lectureSubject.toLowerCase().contains(query) ||
        e.teacherName.toLowerCase().contains(query);
  }

  int _compareEntries(MonitorEntry a, MonitorEntry b) {
    if (a.isWatching != b.isWatching) return a.isWatching ? -1 : 1;
    switch (_sort) {
      case MonitorSort.activity:
      case MonitorSort.viewers:
        final aAt = a.lastActivity;
        final bAt = b.lastActivity;
        if (aAt == null && bAt == null) break;
        if (aAt == null) return 1;
        if (bAt == null) return -1;
        final c = bAt.compareTo(aAt);
        if (c != 0) return c;
      case MonitorSort.percent:
        final c = b.percent.compareTo(a.percent);
        if (c != 0) return c;
      case MonitorSort.watched:
        final c = b.watchedSeconds.compareTo(a.watchedSeconds);
        if (c != 0) return c;
      case MonitorSort.name:
        break;
    }
    return a.userName.compareTo(b.userName);
  }

  int _compareGroups(LectureGroup a, LectureGroup b) {
    switch (_sort) {
      case MonitorSort.viewers:
      case MonitorSort.activity:
        final c = b.activeViewers.compareTo(a.activeViewers);
        if (c != 0) return c;
        final aAt = a.lastActivity;
        final bAt = b.lastActivity;
        if (aAt != null && bAt != null) {
          final d = bAt.compareTo(aAt);
          if (d != 0) return d;
        }
      case MonitorSort.percent:
        final c = b.averagePercent.compareTo(a.averagePercent);
        if (c != 0) return c;
      case MonitorSort.watched:
        final c = b.entries
            .fold<double>(0, (s, e) => s + e.watchedSeconds)
            .compareTo(
              a.entries.fold<double>(0, (s, e) => s + e.watchedSeconds),
            );
        if (c != 0) return c;
      case MonitorSort.name:
        break;
    }
    return a.title.compareTo(b.title);
  }

  List<LectureGroup> _groupByLecture(List<MonitorEntry> entries) {
    final map = <String, List<MonitorEntry>>{};
    for (final e in entries) {
      final id = e.lectureId;
      if (id == null || id.isEmpty) continue;
      map.putIfAbsent(id, () => []).add(e);
    }

    final groups = map.entries.map((entry) {
      final first = entry.value.first;
      final sorted = entry.value.toList()..sort(_compareEntries);
      return LectureGroup(
        lectureId: entry.key,
        title: first.lectureTitle,
        subject: first.lectureSubject,
        teacherName: first.teacherName,
        entries: sorted,
      );
    }).toList();

    groups.sort(_compareGroups);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final viewer = context.watch<AuthService>().currentUser;
    if (!PermissionUtils.seesAllGenders(viewer)) {
      return const _MonitorDenied();
    }

    final data = context.watch<ApiDataService>();
    final realtime = context.watch<RealtimeService>();
    final responsive = ResponsiveLayout.of(context);
    final hPad = responsive.horizontalPadding;

    final all = _buildEntries(data, realtime, viewer);
    final filtered = all.where(_matches).toList()..sort(_compareEntries);
    final groups = _grouping == MonitorGrouping.lectures
        ? _groupByLecture(filtered)
        : const <LectureGroup>[];

    final onlineCount = all.where((e) => e.online).length;
    final watchingCount = all.where((e) => e.isWatching).length;
    final activeLectures = all
        .where((e) => e.isWatching)
        .map((e) => e.lectureId)
        .whereType<String>()
        .toSet()
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, responsive.spacing(4), hPad, 0),
          child: _MonitorHeader(
            status: realtime.status,
            onlineCount: onlineCount,
            watchingCount: watchingCount,
            activeLectures: activeLectures,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, responsive.spacing(14), hPad, 0),
          child: AppSearchField(
            controller: _searchController,
            hintText: 'ابحث بالطالب أو المحاضرة أو المادة أو الأستاذ...',
            onChanged: (value) => setState(() => _query = value),
            onClear: _clearSearch,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, responsive.spacing(12), hPad, 0),
          child: _GroupingToggle(
            value: _grouping,
            onChanged: (value) => setState(() => _grouping = value),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            hPad,
            responsive.spacing(10),
            hPad,
            responsive.spacing(10),
          ),
          child: _ControlsRow(
            sort: _sort,
            statusFilter: _statusFilter,
            hasActiveFilters: _hasActiveFilters,
            resultCount: _grouping == MonitorGrouping.students
                ? filtered.length
                : groups.length,
            onSortChanged: (value) => setState(() => _sort = value),
            onStatusChanged: (value) => setState(() => _statusFilter = value),
            onOpenFilters: () => _openFilterSheet(data, all),
            onResetFilters: _resetFilters,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: _buildBody(filtered, groups, responsive),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    List<MonitorEntry> entries,
    List<LectureGroup> groups,
    ResponsiveLayout responsive,
  ) {
    if (_loadingStored && entries.isEmpty) {
      return const Center(child: AppLoadingIndicator());
    }

    if (_grouping == MonitorGrouping.lectures) {
      if (groups.isEmpty) {
        return _MonitorEmptyState(
          hasQuery: _query.trim().isNotEmpty || _hasActiveFilters,
          grouping: _grouping,
        );
      }
      return ListView.builder(
        padding: responsive.listPadding(),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: groups.length,
        itemBuilder: (context, index) => RepaintBoundary(
          child: _LectureGroupCard(
            key: ValueKey(groups[index].lectureId),
            group: groups[index],
          ),
        ),
      );
    }

    if (entries.isEmpty) {
      return _MonitorEmptyState(
        hasQuery: _query.trim().isNotEmpty || _hasActiveFilters,
        grouping: _grouping,
      );
    }

    return ListView.builder(
      padding: responsive.listPadding(),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) => RepaintBoundary(
        child: _StudentMonitorCard(
          key: ValueKey(entries[index].userId),
          entry: entries[index],
        ),
      ),
    );
  }

  Future<void> _openFilterSheet(
    ApiDataService data,
    List<MonitorEntry> entries,
  ) async {
    final subjects =
        entries
            .map((e) => e.lectureSubject)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final sections =
        entries
            .map((e) => e.section)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final teachers =
        entries
            .map((e) => e.teacherName)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _FilterSheet(
        subjects: subjects,
        sections: sections,
        teachers: teachers,
        subject: _subjectFilter,
        section: _sectionFilter,
        teacher: _teacherFilter,
        onApply: (subject, section, teacher) {
          setState(() {
            _subjectFilter = subject;
            _sectionFilter = section;
            _teacherFilter = teacher;
          });
        },
      ),
    );
  }
}

class _MonitorDenied extends StatelessWidget {
  const _MonitorDenied();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppLayout.pagePaddingOf(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 52,
              color: AppColors.textSecondary(context).withValues(alpha: 0.35),
            ),
            const SizedBox(height: 14),
            Text(
              'هذه الصفحة مخصّصة للإدارة والأساتذة',
              textAlign: TextAlign.center,
              style: AppFonts.readex(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonitorHeader extends StatelessWidget {
  final RealtimeStatus status;
  final int onlineCount;
  final int watchingCount;
  final int activeLectures;

  const _MonitorHeader({
    required this.status,
    required this.onlineCount,
    required this.watchingCount,
    required this.activeLectures,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkPrimaryGradient
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: isDark ? 0.4 : 0.26),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              LiveStatusDot(status: status),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  switch (status) {
                    RealtimeStatus.connected => 'بث مباشر — تحديث لحظي',
                    RealtimeStatus.connecting => 'جاري الاتصال...',
                    RealtimeStatus.disconnected => 'غير متصل — إعادة المحاولة',
                  },
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.readex(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: Colors.white.withValues(alpha: 0.94),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final metrics = [
                (
                  icon: Icons.play_circle_rounded,
                  value: '$watchingCount',
                  label: 'يشاهدون',
                ),
                (
                  icon: Icons.wifi_tethering_rounded,
                  value: '$onlineCount',
                  label: 'متصل',
                ),
                (
                  icon: Icons.video_library_rounded,
                  value: '$activeLectures',
                  label: 'محاضرة نشطة',
                ),
              ];

              return Row(
                children: [
                  for (var i = 0; i < metrics.length; i++) ...[
                    if (i > 0)
                      Container(
                        width: 1,
                        height: 38,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    Expanded(
                      child: _HeaderMetric(
                        icon: metrics[i].icon,
                        value: metrics[i].value,
                        label: metrics[i].label,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: motionDuration(context, AppMotion.quick),
            child: Text(
              value,
              key: ValueKey(value),
              style: AppFonts.readex(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.82)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.readex(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LiveStatusDot extends StatefulWidget {
  final RealtimeStatus status;
  final double size;

  const LiveStatusDot({super.key, required this.status, this.size = 14});

  @override
  State<LiveStatusDot> createState() => _LiveStatusDotState();
}

class _LiveStatusDotState extends State<LiveStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = widget.status == RealtimeStatus.connected;
    final animate = live && !prefersReducedMotion(context);

    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }

    final color = switch (widget.status) {
      RealtimeStatus.connected => const Color(0xFF4ADE80),
      RealtimeStatus.connecting => const Color(0xFFFBBF24),
      RealtimeStatus.disconnected => const Color(0xFFF87171),
    };

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final core = widget.size * 0.57;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (animate)
                Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0) * 0.5,
                  child: Container(
                    width: core + (widget.size - core) * 2 * t,
                    height: core + (widget.size - core) * 2 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                ),
              Container(
                width: core,
                height: core,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupingToggle extends StatelessWidget {
  final MonitorGrouping value;
  final ValueChanged<MonitorGrouping> onChanged;

  const _GroupingToggle({required this.value, required this.onChanged});

  static const _options = [
    (
      value: MonitorGrouping.students,
      label: 'حسب الطالب',
      icon: Icons.people_alt_rounded,
    ),
    (
      value: MonitorGrouping.lectures,
      label: 'حسب المحاضرة',
      icon: Icons.video_library_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: _options.map((option) {
          final selected = option.value == value;
          return Expanded(
            child: Semantics(
              selected: selected,
              button: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (selected) return;
                    HapticFeedback.selectionClick();
                    onChanged(option.value);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: motionDuration(context, AppMotion.quick),
                    curve: AppMotion.standardCurve,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: selected
                          ? (isDark
                                ? AppColors.darkPrimaryGradient
                                : AppColors.primaryGradient)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option.icon,
                          size: 15,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary(context),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            option.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.readex(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              height: 1.3,
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
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ControlsRow extends StatelessWidget {
  final MonitorSort sort;
  final WatchStatus? statusFilter;
  final bool hasActiveFilters;
  final int resultCount;
  final ValueChanged<MonitorSort> onSortChanged;
  final ValueChanged<WatchStatus?> onStatusChanged;
  final VoidCallback onOpenFilters;
  final VoidCallback onResetFilters;

  const _ControlsRow({
    required this.sort,
    required this.statusFilter,
    required this.hasActiveFilters,
    required this.resultCount,
    required this.onSortChanged,
    required this.onStatusChanged,
    required this.onOpenFilters,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            children: [
              _MiniChip(
                label: 'الكل',
                icon: Icons.all_inclusive_rounded,
                selected: statusFilter == null,
                onTap: () => onStatusChanged(null),
              ),
              for (final status in WatchStatus.values) ...[
                const SizedBox(width: 7),
                _MiniChip(
                  label: status.label,
                  icon: status.icon,
                  selected: statusFilter == status,
                  accent: status.color(context),
                  onTap: () => onStatusChanged(status),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            const Spacer(),
            if (hasActiveFilters) ...[
              _IconAction(
                icon: Icons.filter_alt_off_rounded,
                label: 'إزالة عوامل التصفية',
                onTap: onResetFilters,
              ),
              const SizedBox(width: 8),
            ],
            _IconAction(
              icon: Icons.tune_rounded,
              label: 'تصفية متقدمة',
              highlighted: hasActiveFilters,
              onTap: onOpenFilters,
            ),
            const SizedBox(width: 8),
            PopupMenuButton<MonitorSort>(
              tooltip: 'الترتيب',
              initialValue: sort,
              onSelected: onSortChanged,
              itemBuilder: (context) => [
                for (final option in MonitorSort.values)
                  PopupMenuItem<MonitorSort>(
                    value: option,
                    child: Row(
                      children: [
                        Icon(
                          option.icon,
                          size: 17,
                          color: AppColors.icon(context),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          option.label,
                          style: AppFonts.readex(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
              ],
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sort.icon,
                      size: 15,
                      color: AppColors.textSecondary(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sort.label,
                      style: AppFonts.readex(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color? accent;
  final VoidCallback onTap;

  const _MiniChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primary;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: AnimatedContainer(
            duration: motionDuration(context, AppMotion.quick),
            padding: const EdgeInsets.symmetric(horizontal: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.16)
                  : AppColors.surface(context),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.45)
                    : AppColors.border(context),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: selected ? color : AppColors.textSecondary(context),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AppFonts.readex(
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    height: 1.3,
                    color: selected ? color : AppColors.textSecondary(context),
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

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: highlighted
              ? AppColors.roleBadgeBg(context)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: highlighted
                      ? AppColors.roleBadgeBorder(context)
                      : AppColors.border(context),
                ),
              ),
              child: Icon(
                icon,
                size: 17,
                color: highlighted
                    ? AppColors.roleBadgeText(context)
                    : AppColors.textSecondary(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentMonitorCard extends StatelessWidget {
  final MonitorEntry entry;

  const _StudentMonitorCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final status = entry.status;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppLayout.itemGap),
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/user/${entry.userId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MonitorAvatar(
                name: entry.userName,
                photoPath: entry.photoPath,
                online: entry.online,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.readex(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 11,
                          color: AppColors.textSecondary(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            MonitorFormat.relative(entry.lastActivity),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.readex(
                              fontSize: 11.5,
                              height: 1.35,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: status),
            ],
          ),
          if (entry.lectureId != null) ...[
            const SizedBox(height: 12),
            _WatchDetails(entry: entry),
          ],
        ],
      ),
    );
  }
}

class MonitorAvatar extends StatelessWidget {
  final String name;
  final String? photoPath;
  final bool online;
  final double size;

  const MonitorAvatar({
    super.key,
    required this.name,
    required this.photoPath,
    required this.online,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          UserAvatar(
            name: name,
            photoPath: photoPath,
            size: size,
            showBorder: false,
            showShadow: false,
          ),
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: Container(
              width: size * 0.29,
              height: size * 0.29,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: online
                    ? const Color(0xFF22C55E)
                    : AppColors.textSecondary(context).withValues(alpha: 0.5),
                border: Border.all(
                  color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  width: 2.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final WatchStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 12,
            color: color,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: AppFonts.readex(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchDetails extends StatelessWidget {
  final MonitorEntry entry;

  const _WatchDetails({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_outline_rounded,
                size: 16,
                color: AppColors.roleBadgeText(context),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  entry.lectureTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.readex(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          if (entry.lectureSubject.isNotEmpty ||
              entry.teacherName.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              [
                if (entry.lectureSubject.isNotEmpty) entry.lectureSubject,
                if (entry.teacherName.isNotEmpty) entry.teacherName,
              ].join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.readex(
                fontSize: 11.5,
                height: 1.35,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
          const SizedBox(height: 10),
          ProgressTrack(percent: entry.percent, completed: entry.completed),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Text(
                  MonitorFormat.clock(entry.positionSeconds),
                  style: AppFonts.readex(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  ' / ${MonitorFormat.clock(entry.durationSeconds)}',
                  style: AppFonts.readex(
                    fontSize: 11,
                    height: 1.3,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const Spacer(),
                Text(
                  MonitorFormat.percent(entry.percent),
                  style: AppFonts.readex(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: AppColors.roleBadgeText(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              MetricPill(
                icon: Icons.timelapse_rounded,
                label: 'مُشاهَد',
                value: MonitorFormat.clock(entry.watchedSeconds),
              ),
              MetricPill(
                icon: Icons.event_available_rounded,
                label: 'آخر نشاط',
                value: MonitorFormat.exact(entry.lastActivity),
              ),
              if (entry.live?.startedAt != null)
                MetricPill(
                  icon: Icons.play_arrow_rounded,
                  label: 'البدء',
                  value: DateFormat(
                    'h:mm a',
                    'ar',
                  ).format(entry.live!.startedAt!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProgressTrack extends StatelessWidget {
  final double percent;
  final bool completed;
  final double height;
  final bool animate;

  const ProgressTrack({
    super.key,
    required this.percent,
    required this.completed,
    this.height = 7,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final factor = percent.clamp(0.0, 1.0);

    final fill = Container(
      height: height,
      decoration: BoxDecoration(
        gradient: completed
            ? LinearGradient(
                colors: [
                  AppColors.success_(context),
                  AppColors.success_(context).withValues(alpha: 0.72),
                ],
              )
            : (isDark
                  ? AppColors.darkPrimaryGradient
                  : AppColors.primaryGradient),
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Stack(
          children: [
            Container(height: height, color: AppColors.border(context)),
            if (animate)
              AnimatedFractionallySizedBox(
                duration: motionDuration(context, AppMotion.standard),
                curve: AppMotion.standardCurve,
                widthFactor: factor,
                child: fill,
              )
            else
              FractionallySizedBox(widthFactor: factor, child: fill),
          ],
        ),
      ),
    );
  }
}

class MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const MetricPill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.textSecondary(context)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.readex(
                  fontSize: 10.5,
                  height: 1.3,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.readex(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LectureGroupCard extends StatefulWidget {
  final LectureGroup group;

  const _LectureGroupCard({super.key, required this.group});

  @override
  State<_LectureGroupCard> createState() => _LectureGroupCardState();
}

class _LectureGroupCardState extends State<_LectureGroupCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppLayout.itemGap),
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _expanded = !_expanded);
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (group.subject.isNotEmpty)
                      SubjectIcon(subject: group.subject, size: 42)
                    else
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.roleBadgeBg(context),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.video_library_rounded,
                          size: 20,
                          color: AppColors.roleBadgeText(context),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.readex(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          if (group.subject.isNotEmpty ||
                              group.teacherName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (group.subject.isNotEmpty) group.subject,
                                if (group.teacherName.isNotEmpty)
                                  group.teacherName,
                              ].join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.readex(
                                fontSize: 11.5,
                                height: 1.35,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: motionDuration(context, AppMotion.standard),
                      curve: AppMotion.enter,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _CountBadge(
                      icon: Icons.play_circle_rounded,
                      value: '${group.activeViewers}',
                      label: 'يشاهد الآن',
                      accent: const Color(0xFF22C55E),
                    ),
                    _CountBadge(
                      icon: Icons.people_alt_rounded,
                      value: '${group.entries.length}',
                      label: 'إجمالي',
                    ),
                    _CountBadge(
                      icon: Icons.verified_rounded,
                      value: '${group.completedCount}',
                      label: 'أكملوا',
                      accent: AppColors.success_(context),
                    ),
                    _CountBadge(
                      icon: Icons.percent_rounded,
                      value: MonitorFormat.percent(group.averagePercent),
                      label: 'متوسط',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ProgressTrack(
                  percent: group.averagePercent,
                  completed: false,
                  height: 6,
                ),
                MotionSize(
                  child: _expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                height: 1,
                                color: AppColors.border(context),
                              ),
                              const SizedBox(height: 8),
                              for (final entry in group.entries)
                                _GroupMemberRow(entry: entry),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? accent;

  const _CountBadge({
    required this.icon,
    required this.value,
    required this.label,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.roleBadgeText(context);

    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              value,
              style: AppFonts.readex(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                height: 1.3,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.readex(
                  fontSize: 10.5,
                  height: 1.3,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupMemberRow extends StatelessWidget {
  final MonitorEntry entry;

  const _GroupMemberRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/user/${entry.userId}'),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                MonitorAvatar(
                  name: entry.userName,
                  photoPath: entry.photoPath,
                  online: entry.online,
                  size: 34,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.readex(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      ProgressTrack(
                        percent: entry.percent,
                        completed: entry.completed,
                        height: 4,
                        animate: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      MonitorFormat.percent(entry.percent),
                      style: AppFonts.readex(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MonitorFormat.clock(entry.positionSeconds),
                      textDirection: TextDirection.ltr,
                      style: AppFonts.readex(
                        fontSize: 10.5,
                        height: 1.3,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                StatusChip(status: entry.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List<String> subjects;
  final List<String> sections;
  final List<String> teachers;
  final String? subject;
  final String? section;
  final String? teacher;
  final void Function(String?, String?, String?) onApply;

  const _FilterSheet({
    required this.subjects,
    required this.sections,
    required this.teachers,
    required this.subject,
    required this.section,
    required this.teacher,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _subject;
  String? _section;
  String? _teacher;

  @override
  void initState() {
    super.initState();
    _subject = widget.subject;
    _section = widget.section;
    _teacher = widget.teacher;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        boxShadow: AppShadows.raised(Theme.of(context).brightness),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'تصفية متقدمة',
              style: AppFonts.readex(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              children: [
                _FilterGroup(
                  title: 'المادة',
                  options: widget.subjects,
                  value: _subject,
                  onChanged: (v) => setState(() => _subject = v),
                ),
                _FilterGroup(
                  title: 'الشعبة',
                  options: widget.sections,
                  value: _section,
                  onChanged: (v) => setState(() => _section = v),
                ),
                _FilterGroup(
                  title: 'الأستاذ',
                  options: widget.teachers,
                  value: _teacher,
                  onChanged: (v) => setState(() => _teacher = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              20 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _subject = null;
                        _section = null;
                        _teacher = null;
                      });
                    },
                    child: Text('مسح', style: AppFonts.readex()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(_subject, _section, _teacher);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: Text(
                      'تطبيق',
                      style: AppFonts.readex(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _FilterGroup({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.readex(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                _MiniChip(
                  label: option,
                  icon: Icons.check_rounded,
                  selected: value == option,
                  onTap: () => onChanged(value == option ? null : option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonitorEmptyState extends StatelessWidget {
  final bool hasQuery;
  final MonitorGrouping grouping;

  const _MonitorEmptyState({required this.hasQuery, required this.grouping});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveLayout.of(context);

    final (icon, title, hint) = hasQuery
        ? (
            Icons.search_off_rounded,
            'لا توجد نتائج',
            'جرّب تعديل البحث أو إزالة عوامل التصفية',
          )
        : grouping == MonitorGrouping.lectures
        ? (
            Icons.video_library_outlined,
            'لا توجد محاضرات قيد المتابعة',
            'ستظهر المحاضرات هنا فور بدء الطلاب بالمشاهدة',
          )
        : (
            Icons.groups_outlined,
            'لا يوجد طلاب لعرضهم',
            'سيظهر الطلاب هنا فور اتصالهم بالتطبيق',
          );

    return ListView(
      padding: responsive.listPadding(),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: responsive.spacing(46)),
        Icon(
          icon,
          size: 54,
          color: AppColors.textSecondary(context).withValues(alpha: 0.3),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppFonts.readex(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hint,
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

enum StaffLecturesTab { manage, monitor }

class StaffLecturesTabBar extends StatelessWidget {
  final StaffLecturesTab value;
  final ValueChanged<StaffLecturesTab> onChanged;

  const StaffLecturesTabBar({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final watching = context.select<RealtimeService, int>(
      (r) => r.watchingCount,
    );
    final status = context.select<RealtimeService, RealtimeStatus>(
      (r) => r.status,
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StaffTabButton(
              label: 'إدارة المحاضرات',
              icon: Icons.video_settings_rounded,
              selected: value == StaffLecturesTab.manage,
              isDark: isDark,
              onTap: () => onChanged(StaffLecturesTab.manage),
            ),
          ),
          Expanded(
            child: _StaffTabButton(
              label: 'المتابعة المباشرة',
              icon: Icons.podcasts_rounded,
              selected: value == StaffLecturesTab.monitor,
              isDark: isDark,
              badge: watching > 0 ? '$watching' : null,
              status: status,
              onTap: () => onChanged(StaffLecturesTab.monitor),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final String? badge;
  final RealtimeStatus? status;
  final VoidCallback onTap;

  const _StaffTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.badge,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (selected) return;
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (status != null && !selected)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: LiveStatusDot(status: status!, size: 10),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      icon,
                      size: 15,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary(context),
                    ),
                  ),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.readex(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      height: 1.3,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary(context),
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.24)
                          : const Color(0xFF22C55E).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge!,
                      style: AppFonts.readex(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF22C55E),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
