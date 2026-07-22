import 'package:flutter/material.dart';

abstract final class AppIcons {
  static const String _baseImg = 'assets/images';
  static const String _baseIco = 'assets/icons';

  static const String logo = '$_baseImg/NewLogo.webp';
  static const String logoMark = '$_baseImg/logo_mark.png';
  static const String home = '$_baseIco/home.svg';
  static const String controlPanel = '$_baseIco/ControlPanel.svg';
  static const String community = '$_baseIco/Community.svg';
  static const String help = '$_baseIco/Help.svg';
  static const String profile = '$_baseIco/Profile.svg';
  static const String settings = '$_baseIco/Settings.svg';
  static const String students = '$_baseIco/students.svg';
  static const String teachers = '$_baseIco/Teacher.svg';
  static const String lectures = '$_baseIco/Lectures.svg';
  static const String menu = '$_baseIco/Menu-Burger.svg';
}

enum AppIconKind {
  home,
  dashboard,
  lectures,
  classmates,
  community,
  profile,
  settings,
  help,
  controlPanel,
  students,
  teachers,
}

extension AppIconKindAssets on AppIconKind {
  String get assetPath => switch (this) {
    AppIconKind.home || AppIconKind.dashboard => AppIcons.home,
    AppIconKind.lectures => AppIcons.lectures,
    AppIconKind.teachers => AppIcons.teachers,
    AppIconKind.classmates || AppIconKind.students => AppIcons.students,
    AppIconKind.community => AppIcons.community,
    AppIconKind.controlPanel => AppIcons.controlPanel,
    AppIconKind.profile => AppIcons.profile,
    AppIconKind.settings => AppIcons.settings,
    AppIconKind.help => AppIcons.help,
  };
}

abstract final class AppStrings {
  static const appName = 'معهد طريق المجد للتعليم';
  static const appShortName = 'طريق المجد';
}

abstract final class AppSections {
  static const List<String> all = ['شعبة أ', 'شعبة ب', 'شعبة ج', 'شعبة د'];

  static String letterFor(String section) {
    return section.replaceFirst('شعبة ', '');
  }
}

class AppSubjects {
  static const List<String> all = [
    'اللغة العربية',
    'اللغة الانكليزية',
    'الرياضيات',
    'الكيمياء',
    'الفيزياء',
    'الاحياء',
  ];

  static const Map<String, String> _bannerAssets = {
    'اللغة العربية': 'assets/images/ArabicLangBanner.webp',
    'اللغة الانكليزية': 'assets/images/EnglishBanner.webp',
    'الرياضيات': 'assets/images/MathematicsBanner.webp',
    'الفيزياء': 'assets/images/PhysicsBanner.webp',
    'الكيمياء': 'assets/images/ChemistryBanner.webp',
    'الاحياء': 'assets/images/BiologyBanner.webp',
  };

  static String? bannerAssetFor(String subject) => _bannerAssets[subject];

  static bool hasBanner(String subject) => _bannerAssets.containsKey(subject);

  static IconData iconFor(String subject) {
    switch (subject) {
      case 'اللغة العربية':
        return Icons.menu_book_rounded;
      case 'اللغة الانكليزية':
        return Icons.translate_rounded;
      case 'الرياضيات':
        return Icons.calculate_rounded;
      case 'الكيمياء':
        return Icons.science_rounded;
      case 'الفيزياء':
        return Icons.bolt_rounded;
      case 'الاحياء':
        return Icons.eco_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  static List<Color> gradientFor(String subject) {
    switch (subject) {
      case 'اللغة العربية':
        return [const Color(0xFF1740A8), const Color(0xFF2E6FE8)];
      case 'اللغة الانكليزية':
        return [const Color(0xFF0369A1), const Color(0xFF38A0F0)];
      case 'الرياضيات':
        return [const Color(0xFF004E89), const Color(0xFF0096C7)];
      case 'الكيمياء':
        return [const Color(0xFF006466), const Color(0xFF00B4D8)];
      case 'الفيزياء':
        return [const Color(0xFF1B4965), const Color(0xFF5FA8D3)];
      case 'الاحياء':
        return [const Color(0xFF2D6A4F), const Color(0xFF52B788)];
      default:
        return [const Color(0xFF2058DB), const Color(0xFF54A8F5)];
    }
  }
}
