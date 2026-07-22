import '../../core/shared_widgets.dart';
import '../../theme/theme.dart';
import '../home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/services.dart';

class ClassmatesScreen extends StatefulWidget {
  final bool showAppBar;

  const ClassmatesScreen({super.key, this.showAppBar = true});

  @override
  State<ClassmatesScreen> createState() => _ClassmatesScreenState();
}

class _ClassmatesScreenState extends State<ClassmatesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthService>().currentUser;
    final allApproved = context.watch<ApiDataService>().students;

    final students = currentUser == null
        ? allApproved
        : allApproved.where((s) => s.gender == currentUser.gender).toList();

    final filtered = _searchQuery.isEmpty
        ? students
        : students
              .where(
                (s) =>
                    s.name.contains(_searchQuery) ||
                    (s.section?.contains(_searchQuery) ?? false),
              )
              .toList();

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
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'ابحث عن زميل...',
              prefixIcon: const Icon(Icons.search_rounded),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppLayout.itemGap),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'لا يوجد زملاء',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : ListView.builder(
                  padding: AppLayout.listPadding(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final student = filtered[index];
                    return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.overlay(0.12)
                                      : AppColors.secondary.withValues(
                                          alpha: 0.14,
                                        ),
                                  child: Text(
                                    student.name.substring(0, 1),
                                    style: TextStyle(
                                      color: AppColors.icon(context),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        student.section ?? '',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (40 * index).ms, duration: 260.ms)
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        );
                  },
                ),
        ),
      ],
    );

    if (!widget.showAppBar) {
      return ShellTabBody(child: content);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('الزملاء')),
      body: content,
    );
  }
}
