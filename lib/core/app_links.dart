import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/theme.dart';
import 'api_data_service.dart';

class AdminContact {
  final String name;
  final String initial;
  final String role;
  final String displayPhone;
  final String dialPhone;

  const AdminContact({
    required this.name,
    required this.initial,
    required this.role,
    required this.displayPhone,
    required this.dialPhone,
  });
}

abstract final class AppContactInfo {
  static const String privacyPolicyUrl = 'https://prv.tareeqalmajd.best';
  static const String supportEmail = 'tareeqalmajd.institute@gmail.com';

  static const List<AdminContact> administration = [
    AdminContact(
      name: 'جعفر المنصور',
      initial: 'ج',
      role: 'الإدارة',
      displayPhone: '+964 774 805 3650',
      dialPhone: '+9647748053650',
    ),
    AdminContact(
      name: 'حيدر المنصور',
      initial: 'ح',
      role: 'الإدارة',
      displayPhone: '+964 774 805 3610',
      dialPhone: '+9647748053610',
    ),
  ];
}

abstract final class AppRefresh {
  static Future<void> reload(
    BuildContext context, {
    Future<void> Function()? also,
    String errorMessage = 'تعذّر تحديث البيانات، تحقق من الاتصال',
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final data = context.read<ApiDataService>();
    try {
      await Future.wait<void>([data.refreshAll(), if (also != null) also()]);
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
    }
  }
}

abstract final class AppLinks {
  static Future<void> openUrl(
    BuildContext context,
    String url, {
    String copyLabel = 'الرابط',
  }) async {
    await _launch(
      context,
      Uri.parse(url),
      copyValue: url,
      failureMessage: 'تعذّر فتح $copyLabel، تم نسخه إلى الحافظة',
    );
  }

  static Future<void> dial(
    BuildContext context,
    String phone, {
    String? displayPhone,
  }) async {
    final shown = displayPhone ?? phone;
    await _launch(
      context,
      Uri(scheme: 'tel', path: phone),
      copyValue: shown,
      failureMessage: 'تعذّر فتح تطبيق الاتصال، تم نسخ الرقم $shown',
    );
  }

  static Future<void> email(
    BuildContext context,
    String address, {
    String? subject,
  }) async {
    await _launch(
      context,
      Uri(
        scheme: 'mailto',
        path: address,
        query: subject == null
            ? null
            : 'subject=${Uri.encodeComponent(subject)}',
      ),
      copyValue: address,
      failureMessage: 'تعذّر فتح تطبيق البريد، تم نسخ العنوان',
    );
  }

  static Future<void> copy(
    BuildContext context,
    String value, {
    required String label,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    await HapticFeedback.selectionClick();
    _notify(messenger, 'تم نسخ $label');
  }

  static Future<void> _launch(
    BuildContext context,
    Uri uri, {
    required String copyValue,
    required String failureMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    await HapticFeedback.lightImpact();

    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }

    if (opened) return;

    await Clipboard.setData(ClipboardData(text: copyValue));
    _notify(messenger, failureMessage, isError: true);
  }

  static void _notify(
    ScaffoldMessengerState messenger,
    String message, {
    bool isError = false,
  }) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : null,
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
