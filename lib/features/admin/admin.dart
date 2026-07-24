import '../../core/core.dart';
import '../../theme/theme.dart';
import '../auth/auth.dart';
import '../classmates/classmates.dart';
import '../community/community.dart';
import '../home/home.dart';
import '../lectures/lectures.dart';
import 'admin_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ApiDataService>();
    final user = context.watch<AuthService>().currentUser;

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
                name: user?.name ?? 'المشرف',
                subtitle:
                    'إدارة المعهد بين يديك، تابع الطلاب والأساتذة والمحاضرات',
                badge: const HomeHeaderBadge(
                  icon: Icons.verified_user_rounded,
                  label: 'مشرف النظام',
                ),
                trailing: user == null
                    ? null
                    : UserAvatar(
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
                      iconKind: AppIconKind.students,
                      label: 'الطلاب',
                      value: '${data.students.length}',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppLayout.itemGap),
                  Expanded(
                    child: HomeStatTile(
                      iconKind: AppIconKind.teachers,
                      label: 'الأساتذة',
                      value: '${data.teachers.length}',
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 80.ms, duration: 340.ms),
              const SizedBox(height: AppLayout.itemGap),
              Row(
                children: [
                  Expanded(
                    child: HomeStatTile(
                      iconKind: AppIconKind.lectures,
                      label: 'المحاضرات',
                      value: '${data.lectures.length}',
                      color: AppColors.info_(context),
                      onTap: () => ShellTabs.of(context)?.select(1),
                    ),
                  ),
                  const SizedBox(width: AppLayout.itemGap),
                  Expanded(
                    child: HomeStatTile(
                      iconKind: AppIconKind.community,
                      label: 'المنشورات',
                      value: '${data.communityPosts.length}',
                      color: AppColors.warning_(context),
                      onTap: () => ShellTabs.of(context)?.select(3),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 120.ms, duration: 340.ms),
              const SizedBox(height: AppLayout.sectionGap),
              const HomeSectionTitle(title: 'إجراءات سريعة'),
              HomeActionCard(
                icon: Icons.admin_panel_settings_rounded,
                title: 'لوحة التحكم',
                subtitle: 'الحسابات، الأدوار، والمواد',
                onTap: () => context.push('/admin/control-panel'),
              ).animate().fadeIn(delay: 160.ms, duration: 320.ms),
              const SizedBox(height: AppLayout.itemGap),
              HomeActionCard(
                icon: Icons.person_add_alt_1_rounded,
                title: 'إضافة طالب',
                subtitle: 'إنشاء حساب طالب مفعّل مباشرة',
                color: AppColors.secondary,
                onTap: () => context.push('/admin/add-student'),
              ).animate().fadeIn(delay: 200.ms, duration: 320.ms),
              const SizedBox(height: AppLayout.itemGap),
              HomeActionCard(
                icon: Icons.school_rounded,
                title: 'إضافة أستاذ',
                subtitle: 'إنشاء حساب أستاذ وتحديد مواده',
                color: AppColors.info_(context),
                onTap: () => context.push('/admin/add-teacher'),
              ).animate().fadeIn(delay: 240.ms, duration: 320.ms),
              const SizedBox(height: AppLayout.itemGap),
              HomeActionCard(
                icon: Icons.fact_check_rounded,
                title: 'الحضور والغياب',
                subtitle: 'تسجيل ومتابعة حضور الطلاب',
                color: AppColors.success_(context),
                onTap: () => context.push('/admin/attendance'),
              ).animate().fadeIn(delay: 280.ms, duration: 320.ms),
              const SizedBox(height: AppLayout.itemGap),
              HomeActionCard(
                icon: Icons.podcasts_rounded,
                title: 'المتابعة المباشرة',
                subtitle: 'من المتصل الآن وأي محاضرة يشاهد',
                color: AppColors.warning_(context),
                onTap: () => context.push('/admin/monitoring'),
              ).animate().fadeIn(delay: 320.ms, duration: 320.ms),
              const SizedBox(height: AppLayout.sectionGap),
              const HomeSectionTitle(title: 'المواد الدراسية'),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppLayout.itemGap,
                  crossAxisSpacing: AppLayout.itemGap,
                  childAspectRatio: 1.35,
                ),
                itemCount: AppSubjects.all.length,
                itemBuilder: (context, index) {
                  final subject = AppSubjects.all[index];
                  return AppCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SubjectIcon(subject: subject, size: 40),
                        const Spacer(),
                        Text(
                          subject,
                          style: AppFonts.readex(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        SubjectTeacherDisplay(subject: subject, compact: true),
                      ],
                    ),
                  ).animate().fadeIn(
                    delay: (320 + 40 * index).ms,
                    duration: 280.ms,
                  );
                },
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      showAdminMenuItem: true,
      tabTitles: const ['الرئيسية', 'المحاضرات', 'الطلاب', 'المجتمع'],
      pages: const [
        AdminDashboardTab(),
        LecturesScreen(showUploadFab: true, showAppBar: false),
        StudentDirectoryScreen(showAppBar: false, title: 'الطلاب'),
        CommunityScreen(showAppBar: false),
      ],
      navItems: const [
        PremiumNavItem(iconKind: AppIconKind.dashboard, label: 'الرئيسية'),
        PremiumNavItem(iconKind: AppIconKind.lectures, label: 'المحاضرات'),
        PremiumNavItem(iconKind: AppIconKind.students, label: 'الطلاب'),
        PremiumNavItem(iconKind: AppIconKind.community, label: 'المجتمع'),
      ],
    );
  }
}

class AdminTeachersScreen extends StatelessWidget {
  final bool embedded;

  const AdminTeachersScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return const TeachersManagementTab(showHeader: true);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('إدارة الأساتذة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'إضافة أستاذ',
            onPressed: () => context.push('/admin/add-teacher'),
          ),
        ],
      ),
      body: const TeachersManagementTab(),
    );
  }
}

class TeachersManagementTab extends StatelessWidget {
  final bool showHeader;

  const TeachersManagementTab({super.key, this.showHeader = false});

  @override
  Widget build(BuildContext context) {
    final teachers = context.watch<ApiDataService>().teachers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader)
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppLayout.horizontalOf(context),
              AppLayout.spacingOf(context, AppLayout.pageTop),
              8,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'إدارة الأساتذة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add_rounded),
                  color: AppColors.primary,
                  tooltip: 'إضافة أستاذ',
                  onPressed: () => context.push('/admin/add-teacher'),
                ),
              ],
            ),
          ),
        Expanded(
          child: teachers.isEmpty
              ? const Center(child: Text('لا يوجد أساتذة'))
              : ListView.builder(
                  padding: AppLayout.listPaddingOf(context),
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    return _TeacherCard(teacher: teachers[index])
                        .animate()
                        .fadeIn(delay: (40 * index).ms, duration: 260.ms)
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        );
                  },
                ),
        ),
      ],
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final UserModel teacher;

  const _TeacherCard({required this.teacher});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ApiDataService>();
    final subjects = data.getSubjectsForTeacher(teacher.id);
    final actor = context.watch<AuthService>().currentUser;
    final canDelete = PermissionUtils.canDeleteUser(
      actor: actor,
      target: teacher,
    );

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.overlay(0.12)
                    : AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  teacher.name.substring(0, 1),
                  style: TextStyle(
                    color: AppColors.icon(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      teacher.username,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditDialog(context);
                  } else if (value == 'delete') {
                    _confirmDelete(context);
                  } else if (value == 'assign') {
                    _showAssignDialog(context);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  const PopupMenuItem(
                    value: 'assign',
                    child: Text('تعيين مواد'),
                  ),
                  if (canDelete)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'حذف',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subjects.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SubjectIcon(subject: s, size: 24, showShadow: false),
                    const SizedBox(width: 8),
                    Text(s, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'صلاحية رفع المحاضرات',
              style: TextStyle(fontSize: 14),
            ),
            value: teacher.canUploadLectures,
            activeThumbColor: AppColors.secondary,
            onChanged: (v) {
              context.read<ApiDataService>().setTeacherUploadPermission(
                teacher.id,
                v,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameController = TextEditingController(text: teacher.name);

    final passwordController = TextEditingController();
    final phoneController = TextEditingController(text: teacher.phone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الأستاذ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              PasswordTextField(
                controller: passwordController,
                labelText: 'كلمة المرور الجديدة (اتركها فارغة لعدم التغيير)',
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'الهاتف'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final dataService = context.read<ApiDataService>();
              final messenger = ScaffoldMessenger.of(context);
              final previousName = teacher.name;
              final previousPassword = teacher.password;
              final previousPhone = teacher.phone;
              teacher.name = nameController.text.trim();
              if (passwordController.text.isNotEmpty) {
                teacher.password = passwordController.text;
              }
              teacher.phone = phoneController.text.trim();
              try {
                await dataService.updateTeacher(teacher);
              } catch (e) {
                teacher.name = previousName;
                teacher.password = previousPassword;
                teacher.phone = previousPhone;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final actor = context.read<AuthService>().currentUser;
    if (!PermissionUtils.canDeleteUser(actor: actor, target: teacher)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('غير مصرح لك بحذف هذا الحساب')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الأستاذ'),
        content: Text('هل تريد حذف ${teacher.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final dataService = context.read<ApiDataService>();
              final messenger = ScaffoldMessenger.of(context);
              final error = await dataService.deleteTeacher(teacher.id);
              if (error != null) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    final data = context.read<ApiDataService>();
    final currentSubjects = data.getSubjectsForTeacher(teacher.id);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعيين مواد - ${teacher.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppSubjects.all.map((subject) {
              final isAssigned = currentSubjects.contains(subject);
              return CheckboxListTile(
                secondary: SubjectIcon(
                  subject: subject,
                  size: 36,
                  showShadow: false,
                ),
                title: Text(subject),
                value: isAssigned,
                onChanged: (v) {
                  if (v == true) {
                    data.assignTeacherToSubject(teacher.id, subject);
                  } else {
                    data.removeTeacherFromSubject(teacher.id, subject);
                  }
                  Navigator.pop(ctx);
                  _showAssignDialog(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

class AdminAddStudentScreen extends StatefulWidget {
  const AdminAddStudentScreen({super.key});

  @override
  State<AdminAddStudentScreen> createState() => _AdminAddStudentScreenState();
}

class _AdminAddStudentScreenState extends State<AdminAddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();

  String _selectedSection = AppSections.all.first;
  String _selectedGender = 'ذكر';
  PremiumButtonState _buttonState = PremiumButtonState.idle;

  final Map<String, bool> _subjects = {
    for (final s in AppSubjects.all) s: false,
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _buttonState = PremiumButtonState.loading);
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final dataService = context.read<ApiDataService>();
    final username = _usernameController.text.trim().isEmpty
        ? 'user_${DateTime.now().millisecondsSinceEpoch % 10000}'
        : _usernameController.text.trim();

    if (dataService.isUsernameTaken(username)) {
      setState(() => _buttonState = PremiumButtonState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اسم المستخدم مستخدم بالفعل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final student = UserModel(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      username: username,
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      section: _selectedSection,
      guardianName: _guardianNameController.text.trim().isEmpty
          ? null
          : _guardianNameController.text.trim(),
      guardianPhone: _guardianPhoneController.text.trim().isEmpty
          ? null
          : _guardianPhoneController.text.trim(),
      gender: _selectedGender,
      subjects: _subjects.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
      role: UserRole.student,
    );

    try {
      await dataService.addStudent(student);
    } catch (e) {
      if (!mounted) return;
      setState(() => _buttonState = PremiumButtonState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    }

    setState(() => _buttonState = PremiumButtonState.success);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تمت إضافة الطالب بنجاح')));
    context.pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _buttonState != PremiumButtonState.idle;
    final responsive = ResponsiveLayout.of(context);
    final sectionGap = responsive.spacing(AppLayout.sectionGap);
    final blockGap = responsive.spacing(AppLayout.blockGap);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: false,
        appBar: AppTopBar(
          title: 'إضافة طالب',
          showLogo: false,
          height: responsive.appBarHeight,
          onBackTap: isBusy ? null : () => context.pop(),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: AppLayout.pagePaddingOf(context, bottomExtra: 16),
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _HeroCard()
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.05, end: 0),
                      SizedBox(height: blockGap),
                      _FormSection(
                        title: 'المعلومات الشخصية',
                        children: [
                          _field(
                            controller: _nameController,
                            label: 'الاسم *',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                            enabled: !isBusy,
                          ),
                          _field(
                            controller: _phoneController,
                            label: 'الهاتف *',
                            icon: Icons.phone_outlined,
                            keyboard: TextInputType.phone,
                            enabled: !isBusy,
                            validator: (v) {
                              if (v!.isEmpty) return 'مطلوب';
                              if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                                return 'أرقام فقط';
                              }
                              return null;
                            },
                          ),
                          _field(
                            controller: _usernameController,
                            label: 'اسم المستخدم',
                            icon: Icons.alternate_email_rounded,
                            enabled: !isBusy,
                          ),
                          PasswordTextField(
                            controller: _passwordController,
                            labelText: 'كلمة المرور *',
                            enabled: !isBusy,
                            validator: (v) => (v == null || v.length < 8)
                                ? '8 أحرف على الأقل'
                                : null,
                          ),
                          PasswordTextField(
                            controller: _confirmPasswordController,
                            labelText: 'تأكيد كلمة المرور *',
                            enabled: !isBusy,
                            validator: (v) {
                              if (v != _passwordController.text) {
                                return 'كلمات المرور غير متطابقة';
                              }
                              return null;
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 80.ms, duration: 420.ms),
                      SizedBox(height: responsive.spacing(AppLayout.cardGap)),
                      _FormSection(
                        title: 'المعلومات الدراسية',
                        children: [
                          PremiumSectionSelector(
                            value: _selectedSection,
                            enabled: !isBusy,
                            onChanged: (section) =>
                                setState(() => _selectedSection = section),
                          ),
                          SizedBox(
                            height: responsive.spacing(AppLayout.itemGap),
                          ),
                          _field(
                            controller: _guardianNameController,
                            label: 'اسم ولي الأمر',
                            icon: Icons.family_restroom_outlined,
                            enabled: !isBusy,
                          ),
                          _field(
                            controller: _guardianPhoneController,
                            label: 'هاتف ولي الأمر',
                            icon: Icons.phone_android_outlined,
                            keyboard: TextInputType.phone,
                            enabled: !isBusy,
                          ),
                          SizedBox(height: responsive.spacing(8)),
                          Text(
                            'الجنس *',
                            style: AppFonts.readex(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          SizedBox(height: responsive.spacing(8)),
                          Row(
                            children: [
                              _GenderChip(
                                label: 'ذكر',
                                selected: _selectedGender == 'ذكر',
                                onTap: isBusy
                                    ? null
                                    : () => setState(
                                        () => _selectedGender = 'ذكر',
                                      ),
                              ),
                              SizedBox(width: responsive.spacing(10)),
                              _GenderChip(
                                label: 'أنثى',
                                selected: _selectedGender == 'أنثى',
                                onTap: isBusy
                                    ? null
                                    : () => setState(
                                        () => _selectedGender = 'أنثى',
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ).animate().fadeIn(delay: 140.ms, duration: 420.ms),
                      SizedBox(height: responsive.spacing(AppLayout.cardGap)),
                      _FormSection(
                        title: 'المواد الدراسية',
                        subtitle: 'اختر المواد التي سيدرسها الطالب',
                        children: [
                          PremiumSubjectSelector(
                            selected: _subjects,
                            enabled: !isBusy,
                            onToggle: (subject) => setState(
                              () => _subjects[subject] =
                                  !(_subjects[subject] ?? false),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms, duration: 420.ms),
                      SizedBox(height: sectionGap),
                      PremiumActionButton(
                        label: 'إضافة الطالب',
                        loadingLabel: 'جاري الإضافة...',
                        state: _buttonState,
                        onPressed: isBusy ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboard,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveLayout.of(context).spacing(12),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboard,
        style: AppFonts.readex(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary(context),
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.icon(context)),
        ),
        validator: validator,
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(ResponsiveLayout.of(context).spacing(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إضافة طالب جديد',
            style: AppFonts.readex(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.secondary : AppColors.primary,
            ),
          ),
          SizedBox(height: ResponsiveLayout.of(context).spacing(8)),
          Text(
            'يتم إنشاء الحساب مفعّلاً مباشرة دون الحاجة لرمز تحقق',
            style: AppFonts.readex(
              fontSize: 14,
              color: AppColors.textSecondary(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = ResponsiveLayout.of(context);

    return AppCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(responsive.spacing(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppFonts.readex(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.secondary : AppColors.primary,
              fontSize: 16,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: responsive.spacing(4)),
            Text(
              subtitle!,
              style: AppFonts.readex(
                fontSize: 13,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
          SizedBox(height: responsive.spacing(16)),
          ...children,
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _GenderChip({required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveLayout.of(context).spacing(12),
          ),
          decoration: BoxDecoration(
            gradient: selected
                ? (isDark
                      ? AppColors.darkPrimaryGradient
                      : AppColors.primaryGradient)
                : null,
            color: selected
                ? null
                : (isDark
                      ? AppColors.overlay(0.08)
                      : Colors.white.withValues(alpha: 0.85)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : (isDark
                        ? AppColors.overlayBorder(0.14)
                        : AppColors.borderLight),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppFonts.readex(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary(context),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminAddTeacherScreen extends StatefulWidget {
  const AdminAddTeacherScreen({super.key});

  @override
  State<AdminAddTeacherScreen> createState() => _AdminAddTeacherScreenState();
}

class _AdminAddTeacherScreenState extends State<AdminAddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  PremiumButtonState _buttonState = PremiumButtonState.idle;
  bool _canUploadLectures = true;

  final Map<String, bool> _subjects = {
    for (final s in AppSubjects.all) s: false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboard,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveLayout.of(context).spacing(12),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboard,
        style: AppFonts.readex(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary(context),
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.icon(context)),
        ),
        validator: validator,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _buttonState = PremiumButtonState.loading);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final dataService = context.read<ApiDataService>();
    final username = _usernameController.text.trim();

    if (dataService.isUsernameTaken(username)) {
      setState(() => _buttonState = PremiumButtonState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اسم المستخدم مستخدم بالفعل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final teacher = UserModel(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      username: username,
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      subjects: _subjects.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
      role: UserRole.teacher,
      canUploadLectures: _canUploadLectures,
    );

    try {
      await dataService.addTeacher(teacher);
    } catch (e) {
      if (!mounted) return;
      setState(() => _buttonState = PremiumButtonState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    }

    setState(() => _buttonState = PremiumButtonState.success);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تمت إضافة الأستاذ بنجاح')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _buttonState != PremiumButtonState.idle;
    final responsive = ResponsiveLayout.of(context);
    final sectionGap = responsive.spacing(AppLayout.sectionGap);
    final blockGap = responsive.spacing(AppLayout.blockGap);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: false,
        appBar: AppTopBar(
          title: 'إضافة أستاذ',
          showLogo: false,
          height: responsive.appBarHeight,
          onBackTap: isBusy ? null : () => context.pop(),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: AppLayout.pagePaddingOf(context, bottomExtra: 16),
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                            margin: EdgeInsets.zero,
                            padding: EdgeInsets.all(responsive.spacing(20)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إضافة أستاذ جديد',
                                  style: AppFonts.readex(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.secondary
                                        : AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: responsive.spacing(8)),
                                Text(
                                  'يتم إنشاء حساب الأستاذ مفعّلاً مباشرة، وبإمكانك تحديد المواد وصلاحية رفع المحاضرات الآن',
                                  style: AppFonts.readex(
                                    fontSize: 14,
                                    color: AppColors.textSecondary(context),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.05, end: 0),
                      SizedBox(height: blockGap),
                      _FormSection(
                        title: 'المعلومات الشخصية',
                        children: [
                          _field(
                            controller: _nameController,
                            label: 'الاسم *',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                            enabled: !isBusy,
                          ),
                          _field(
                            controller: _phoneController,
                            label: 'الهاتف *',
                            icon: Icons.phone_outlined,
                            keyboard: TextInputType.phone,
                            enabled: !isBusy,
                            validator: (v) {
                              if (v!.isEmpty) return 'مطلوب';
                              if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                                return 'أرقام فقط';
                              }
                              return null;
                            },
                          ),
                          _field(
                            controller: _emailController,
                            label: 'البريد الإلكتروني (اختياري)',
                            icon: Icons.email_outlined,
                            keyboard: TextInputType.emailAddress,
                            enabled: !isBusy,
                          ),
                          _field(
                            controller: _usernameController,
                            label: 'اسم المستخدم *',
                            icon: Icons.alternate_email_rounded,
                            enabled: !isBusy,
                            validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                          ),
                          PasswordTextField(
                            controller: _passwordController,
                            labelText: 'كلمة المرور *',
                            enabled: !isBusy,
                            validator: (v) => (v == null || v.length < 8)
                                ? '8 أحرف على الأقل'
                                : null,
                          ),
                          PasswordTextField(
                            controller: _confirmPasswordController,
                            labelText: 'تأكيد كلمة المرور *',
                            enabled: !isBusy,
                            validator: (v) {
                              if (v != _passwordController.text) {
                                return 'كلمات المرور غير متطابقة';
                              }
                              return null;
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 80.ms, duration: 420.ms),
                      SizedBox(height: responsive.spacing(AppLayout.cardGap)),
                      _FormSection(
                        title: 'المواد التي يدرّسها',
                        subtitle:
                            'اختر مادة واحدة أو أكثر (يمكن تعديلها لاحقاً)',
                        children: [
                          PremiumSubjectSelector(
                            selected: _subjects,
                            enabled: !isBusy,
                            onToggle: (subject) => setState(
                              () => _subjects[subject] =
                                  !(_subjects[subject] ?? false),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 140.ms, duration: 420.ms),
                      SizedBox(height: responsive.spacing(AppLayout.cardGap)),
                      _FormSection(
                        title: 'الصلاحيات',
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.spacing(4),
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _canUploadLectures,
                              onChanged: isBusy
                                  ? null
                                  : (v) =>
                                        setState(() => _canUploadLectures = v),
                              activeThumbColor: AppColors.primary,
                              title: Text(
                                'السماح برفع المحاضرات',
                                style: AppFonts.readex(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              subtitle: Text(
                                'يمكن للأستاذ رفع محاضرات جديدة للمواد المُسندة إليه',
                                style: AppFonts.readex(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms, duration: 420.ms),
                      SizedBox(height: sectionGap),
                      PremiumActionButton(
                        label: 'إضافة الأستاذ',
                        loadingLabel: 'جاري الإضافة...',
                        state: _buttonState,
                        onPressed: isBusy ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminControlPanelScreen extends StatefulWidget {
  const AdminControlPanelScreen({super.key});

  @override
  State<AdminControlPanelScreen> createState() =>
      _AdminControlPanelScreenState();
}

class _AdminControlPanelScreenState extends State<AdminControlPanelScreen> {
  ControlPanelSection _section = ControlPanelSection.overview;

  void _onSectionSelected(ControlPanelSection section) {
    if (section == ControlPanelSection.addStudent) {
      context.push('/admin/add-student');
      return;
    }
    if (section == ControlPanelSection.addTeacher) {
      context.push('/admin/add-teacher');
      return;
    }
    setState(() => _section = section);
  }

  int _sectionIndex(ControlPanelSection section) {
    return switch (section) {
      ControlPanelSection.overview => 0,
      ControlPanelSection.accounts => 1,
      ControlPanelSection.roles => 2,
      ControlPanelSection.attendance => 3,
      ControlPanelSection.subjects => 4,
      ControlPanelSection.addStudent => 0,
      ControlPanelSection.addTeacher => 0,
    };
  }

  List<Widget> _sectionPages() {
    return [
      ControlPanelOverviewTab(onNavigate: _onSectionSelected),
      const ControlPanelAccountsTab(),
      const ControlPanelRolesTab(),
      const ControlPanelAttendanceTab(),
      const ControlPanelSubjectsTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveLayout.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: false,
      appBar: AppTopBar(
        title: 'لوحة التحكم',
        showLogo: false,
        onBackTap: () => context.pop(),
        height: responsive.appBarHeight,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: responsive.spacing(10)),
            ControlPanelNavBar(
              selected: _section,
              onSelected: _onSectionSelected,
            ),
            SizedBox(height: responsive.spacing(12)),
            Expanded(
              child: IndexedStack(
                index: _sectionIndex(_section),
                children: _sectionPages(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveLayout.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: false,
      appBar: AppTopBar(
        title: 'الحضور والغياب',
        showLogo: false,
        onBackTap: () => context.pop(),
        height: responsive.appBarHeight,
      ),
      body: const SafeArea(top: false, child: ControlPanelAttendanceTab()),
    );
  }
}
