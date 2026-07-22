import '../../core/core.dart';
import '../../theme/theme.dart';
import '../auth/auth.dart';
import '../home/home.dart';
import 'lectures_widgets.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class LecturesScreen extends StatefulWidget {
  final bool showUploadFab;
  final bool showAppBar;

  const LecturesScreen({
    super.key,
    this.showUploadFab = false,
    this.showAppBar = true,
  });

  @override
  State<LecturesScreen> createState() => _LecturesScreenState();
}

class _LecturesScreenState extends State<LecturesScreen> {
  String _selectedSubject = AppSubjects.all.first;
  String _selectedSection = AppSections.all.first;
  String? _studentSelectedSubject;

  bool get _isAdminView {
    final auth = context.read<AuthService>();
    return widget.showUploadFab || auth.canUploadLectures;
  }

  List<String> _availableSubjects(AuthService auth, ApiDataService data) {
    if (auth.isAdmin) return AppSubjects.all;
    if (auth.isTeacher && auth.currentUser != null) {
      final teacherSubjects = data.getSubjectsForTeacher(auth.currentUser!.id);
      return teacherSubjects.isNotEmpty ? teacherSubjects : AppSubjects.all;
    }
    return AppSubjects.all;
  }

  List<LectureModel> _adminLectures(ApiDataService data) {
    return data.getLecturesForSubjectAndSection(
      subject: _selectedSubject,
      section: _selectedSection,
    );
  }

  Future<void> _openAddLectureDialog() async {
    final result = await showAddLectureDialog(
      context,
      initialSubject: _selectedSubject,
      initialSection: _selectedSection,
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نشر المحاضرة بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ApiDataService>();
    final auth = context.watch<AuthService>();

    if (auth.isStudent) {
      return _buildStudentView(data, auth);
    }

    if (_isAdminView) {
      return _buildAdminView(data, auth);
    }

    return _buildStudentView(data, auth);
  }

  Widget _buildAdminView(ApiDataService data, AuthService auth) {
    final subjects = _availableSubjects(auth, data);
    if (!subjects.contains(_selectedSubject)) {
      _selectedSubject = subjects.first;
    }

    final lectures = _adminLectures(data);
    final teachersCount = context.select<ApiDataService, int>(
      (d) => d.getTeachersForSubject(_selectedSubject).length,
    );

    final content = SingleChildScrollView(
      padding: AppLayout.pagePadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'إدارة المحاضرات',
            style: AppFonts.readex(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'اختر المادة والشعبة ثم أضف محاضرة جديدة',
            style: AppFonts.readex(
              fontSize: 13,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: AppLayout.blockGap),
          PremiumSubjectDropdown(
            value: _selectedSubject,
            subjects: subjects,
            onChanged: (v) => setState(() => _selectedSubject = v),
          ),
          const SizedBox(height: AppLayout.itemGap),
          PremiumSectionSelector(
            value: _selectedSection,
            onChanged: (v) => setState(() => _selectedSection = v),
          ),
          const SizedBox(height: AppLayout.sectionGap),
          PremiumActionButton(
            label: 'إضافة محاضرة',
            onPressed: _openAddLectureDialog,
          ),
          const SizedBox(height: 12),
          ViewTeachersButton(
            subject: _selectedSubject,
            teacherCount: teachersCount,
            expand: true,
          ),
          const SizedBox(height: AppLayout.sectionGap),
          Row(
            children: [
              Text(
                'المحاضرات المنشورة',
                style: AppFonts.readex(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${lectures.length}',
                  style: AppFonts.readex(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.itemGap),
          if (lectures.isEmpty)
            _EmptyLecturesState(
              message: 'لا توجد محاضرات لهذه المادة والشعبة',
              hint: 'اضغط "إضافة محاضرة" للبدء',
            )
          else
            ...lectures.asMap().entries.map(
              (entry) => PremiumLectureCard(
                lecture: entry.value,
                showFavorite: false,
                showManageMenu: true,
                animationIndex: entry.key,
                onManageChanged: () => setState(() {}),
              ),
            ),
        ],
      ),
    );

    if (!widget.showAppBar) {
      return ShellTabScaffold(body: content);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('المحاضرات')),
      body: content,
    );
  }

  Widget _buildStudentView(ApiDataService data, AuthService auth) {
    final user = auth.currentUser;
    final section = user?.section ?? AppSections.all.first;
    final subjects = user?.subjects ?? AppSubjects.all;
    final counts = data.getLectureCountsBySubject(
      subjects: subjects,
      section: section,
    );

    if (_studentSelectedSubject != null) {
      final subject = _studentSelectedSubject!;
      final subjectLectures = data.getLecturesForStudentData(
        subjects: [subject],
        section: section,
      );
      final lectures = subjectLectures
          .asMap()
          .entries
          .map(
            (entry) => PremiumLectureCard(
              lecture: entry.value,
              animationIndex: entry.key,
            ),
          )
          .toList();

      final content = StudentLectureList(
        subject: subject,
        lectureCount: counts[subject] ?? 0,
        lectures: lectures,
        onBack: () => setState(() => _studentSelectedSubject = null),
      );

      if (!widget.showAppBar) {
        return ShellTabScaffold(body: content);
      }
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(subject)),
        body: content,
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.pageHorizontal,
            AppLayout.pageTop,
            AppLayout.pageHorizontal,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'محاضراتي',
                style: AppFonts.readex(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'اختر مادة لعرض المحاضرات • $section',
                style: AppFonts.readex(
                  fontSize: 13,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppLayout.itemGap),
        Expanded(
          child: subjects.isEmpty
              ? const _EmptyLecturesState(
                  message: 'لا توجد مواد مسجّلة',
                  hint: 'تواصل مع الإدارة',
                )
              : StudentSubjectGrid(
                  subjects: subjects,
                  lectureCounts: counts,
                  onSubjectTap: (subject) =>
                      setState(() => _studentSelectedSubject = subject),
                ),
        ),
      ],
    );

    if (!widget.showAppBar) {
      return ShellTabScaffold(body: content);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('المحاضرات')),
      body: content,
    );
  }
}

class _EmptyLecturesState extends StatelessWidget {
  final String message;
  final String hint;

  const _EmptyLecturesState({required this.message, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 56,
            color: AppColors.icon(context).withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppFonts.readex(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: AppFonts.readex(
              fontSize: 13,
              color: AppColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class UploadLectureScreen extends StatefulWidget {
  const UploadLectureScreen({super.key});

  @override
  State<UploadLectureScreen> createState() => _UploadLectureScreenState();
}

class _UploadLectureScreenState extends State<UploadLectureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedSubject;
  String? _selectedTeacherId;
  File? _videoFile;
  String? _videoFileName;
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  final _picker = ImagePicker();

  Future<void> _pickVideo() async {
    if (_isUploading) return;
    final picked = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(hours: 4),
    );

    if (picked != null) {
      setState(() {
        _videoFile = File(picked.path);
        _videoFileName = picked.name;
      });
    }
  }

  Future<void> _upload() async {
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

    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار ملف فيديو'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      await context.read<ApiDataService>().addLectureData(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        subject: _selectedSubject!,
        section: AppSections.all.first,
        teacherId: _selectedTeacherId!,
        videoFile: _videoFile!,
        onUploadProgress: (p) {
          if (!mounted) return;
          setState(() => _uploadProgress = p);
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم رفع المحاضرة بنجاح')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل الرفع: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ApiDataService>();
    final auth = context.read<AuthService>();
    final teachers = auth.isAdmin
        ? data.teachers
        : [if (auth.currentUser != null) auth.currentUser!];

    if (_selectedSubject == null && AppSubjects.all.isNotEmpty) {
      _selectedSubject = AppSubjects.all.first;
    }
    if (_selectedTeacherId == null && teachers.isNotEmpty) {
      _selectedTeacherId = teachers.first.id;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('رفع محاضرة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان المحاضرة *',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'الوصف',
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'المادة *',
                        prefixIcon: Icon(Icons.book),
                      ),
                      items: AppSubjects.all
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  SubjectIcon(
                                    subject: s,
                                    size: 32,
                                    showShadow: false,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(s)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSubject = v),
                      validator: (v) => v == null ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    if (auth.isAdmin)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTeacherId,
                        decoration: const InputDecoration(
                          labelText: 'الأستاذ *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: data.teachers
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedTeacherId = v),
                        validator: (v) => v == null ? 'مطلوب' : null,
                      ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _isUploading ? null : _pickVideo,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _videoFile != null
                                ? AppColors.secondary
                                : AppColors.border(context),
                            width: 2,
                          ),
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.overlay(0.08)
                              : AppColors.primary.withValues(alpha: 0.04),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _videoFile != null
                                  ? Icons.check_circle_rounded
                                  : Icons.video_file_rounded,
                              size: 48,
                              color: _videoFile != null
                                  ? AppColors.success
                                  : AppColors.icon(context),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _videoFileName ?? 'اختر ملف فيديو من الجهاز',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _videoFile != null
                                    ? AppColors.textPrimary(context)
                                    : AppColors.textSecondary(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isUploading) ...[
                const SizedBox(height: 16),
                UploadProgressWidget(
                  status: UploadStatus.uploading,
                  progress: _uploadProgress,
                  fileName: _videoFileName,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploading ? null : _upload,
                child: _isUploading
                    ? const AppLoadingIndicator(size: 20)
                    : const Text('رفع المحاضرة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LectureDetailScreen extends StatelessWidget {
  final String lectureId;

  const LectureDetailScreen({super.key, required this.lectureId});

  @override
  Widget build(BuildContext context) {
    return Selector<ApiDataService, LectureModel?>(
      selector: (_, data) => data.findLectureById(lectureId),
      builder: (context, lecture, _) {
        if (lecture == null) {
          return AppBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppTopBar(
                title: 'المحاضرة',
                showLogo: false,
                onBackTap: () => context.pop(),
              ),
              body: Center(
                child: Text(
                  'المحاضرة غير موجودة',
                  style: AppFonts.readex(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          );
        }

        return _LectureDetailBody(lecture: lecture);
      },
    );
  }
}

class _LectureDetailBody extends StatelessWidget {
  final LectureModel lecture;

  const _LectureDetailBody({required this.lecture});

  void _onDurationResolved(BuildContext context, Duration duration) {
    context.read<ApiDataService>().updateLectureDuration(
      lecture.id,
      VideoFormatUtils.formatDuration(duration),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<ApiDataService, ({double avg, int count})>(
      selector: (_, data) => (
        avg: data.getAverageRating(lecture.id),
        count: data.getRatingCount(lecture.id),
      ),
      builder: (context, rating, _) {
        return AppBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppTopBar(
              title: 'المحاضرة',
              showLogo: false,
              onBackTap: () => context.pop(),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: LectureManageMenu(
                    lecture: lecture,
                    onChanged: () {
                      if (context.read<ApiDataService>().findLectureById(
                            lecture.id,
                          ) ==
                          null) {
                        context.pop();
                      }
                    },
                  ),
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppLayout.pageHorizontal,
                    AppLayout.pageTop,
                    AppLayout.pageHorizontal,
                    0,
                  ),
                  child: PremiumVideoPlayer(
                    key: ValueKey(lecture.videoPath),
                    videoPath: lecture.videoPath,
                    posterPath: lecture.coverImagePath,
                    onDurationResolved: (duration) =>
                        _onDurationResolved(context, duration),
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          AppLayout.pageHorizontal,
                          AppLayout.blockGap,
                          AppLayout.pageHorizontal,
                          0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _LectureHeaderCard(
                                lecture: lecture,
                                averageRating: rating.avg,
                                ratingCount: rating.count,
                              ),
                              const SizedBox(height: AppLayout.sectionGap),
                              LectureRatingSection(lectureId: lecture.id),
                              const SizedBox(height: AppLayout.sectionGap),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          AppLayout.pageHorizontal,
                          0,
                          AppLayout.pageHorizontal,
                          AppLayout.pageBottom,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: LectureCommentsSection(lectureId: lecture.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LectureHeaderCard extends StatelessWidget {
  final LectureModel lecture;
  final double averageRating;
  final int ratingCount;

  const _LectureHeaderCard({
    required this.lecture,
    required this.averageRating,
    required this.ratingCount,
  });

  @override
  Widget build(BuildContext context) {
    final teacher = context.select<ApiDataService, UserModel?>(
      (data) => data.findUserById(lecture.teacherId),
    );
    final teacherName = (teacher?.name.trim().isNotEmpty ?? false)
        ? teacher!.name
        : (lecture.teacherName.trim().isNotEmpty
              ? lecture.teacherName
              : 'غير محدّد');

    return AppCard(
      padding: const EdgeInsets.all(18),
      borderRadius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubjectIcon(subject: lecture.subject, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lecture.title,
                      style: AppFonts.readex(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        LectureRatingBadge(
                          average: averageRating,
                          count: ratingCount,
                        ),
                        if (ratingCount > 0 && lecture.duration != null)
                          const SizedBox(width: 8),
                        if (lecture.duration != null)
                          _MetaPill(
                            icon: Icons.schedule_rounded,
                            label: lecture.duration!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.10),
                  AppColors.secondary.withValues(alpha: 0.06),
                ],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              children: [
                UserAvatar(
                  name: teacherName,
                  photoPath: teacher?.photoPath,
                  size: 50,
                  showShadow: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أستاذ المادة',
                        style: AppFonts.readex(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.icon(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        teacherName,
                        style: AppFonts.readex(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.verified_rounded,
                  size: 20,
                  color: AppColors.icon(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(icon: Icons.menu_book_rounded, label: lecture.subject),
              _MetaPill(icon: Icons.class_rounded, label: lecture.section),
              _MetaPill(
                icon: Icons.calendar_today_rounded,
                label: lecture.date,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.icon(context)),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppFonts.readex(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}
