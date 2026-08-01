import '../../core/core.dart';
import '../lectures/live_monitoring.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppTopBar(
        title: 'المتابعة المباشرة',
        onBackTap: () => context.pop(),
        height: AppTopBar.heightOf(context),
      ),
      body: const SafeArea(top: false, child: LiveMonitoringView()),
    );
  }
}
