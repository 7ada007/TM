class ViewerState {
  final String userId;
  final String userName;
  final String section;
  final bool online;
  final String? lectureId;
  final String? lectureTitle;
  final String? lectureSubject;
  final bool playing;
  final double positionSeconds;
  final double durationSeconds;
  final double watchedSeconds;
  final double percent;
  final bool completed;
  final DateTime? startedAt;
  final DateTime? lastSeenAt;

  const ViewerState({
    required this.userId,
    required this.userName,
    required this.section,
    required this.online,
    this.lectureId,
    this.lectureTitle,
    this.lectureSubject,
    this.playing = false,
    this.positionSeconds = 0,
    this.durationSeconds = 0,
    this.watchedSeconds = 0,
    this.percent = 0,
    this.completed = false,
    this.startedAt,
    this.lastSeenAt,
  });

  bool get isWatching => online && (lectureId?.isNotEmpty ?? false);

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  static String? _toStringOrNull(Object? value) {
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  static DateTime? _toDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  factory ViewerState.fromJson(Map<String, dynamic> json) {
    return ViewerState(
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      section: json['section'] as String? ?? '',
      online: json['online'] as bool? ?? false,
      lectureId: _toStringOrNull(json['lectureId']),
      lectureTitle: _toStringOrNull(json['lectureTitle']),
      lectureSubject: _toStringOrNull(json['lectureSubject']),
      playing: json['playing'] as bool? ?? false,
      positionSeconds: _toDouble(json['positionSeconds']),
      durationSeconds: _toDouble(json['durationSeconds']),
      watchedSeconds: _toDouble(json['watchedSeconds']),
      percent: _toDouble(json['percent']).clamp(0.0, 1.0),
      completed: json['completed'] as bool? ?? false,
      startedAt: _toDate(json['startedAt']),
      lastSeenAt: _toDate(json['lastSeenAt']),
    );
  }
}

class LectureProgressRecord {
  final String userId;
  final String lectureId;
  final DateTime? startedAt;
  final double lastPositionSeconds;
  final double watchedSeconds;
  final double durationSeconds;
  final double percent;
  final bool completed;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  const LectureProgressRecord({
    required this.userId,
    required this.lectureId,
    this.startedAt,
    this.lastPositionSeconds = 0,
    this.watchedSeconds = 0,
    this.durationSeconds = 0,
    this.percent = 0,
    this.completed = false,
    this.completedAt,
    this.updatedAt,
  });

  factory LectureProgressRecord.fromJson(Map<String, dynamic> json) {
    return LectureProgressRecord(
      userId: json['userId'] as String? ?? '',
      lectureId: json['lectureId'] as String? ?? '',
      startedAt: ViewerState._toDate(json['startedAt']),
      lastPositionSeconds: ViewerState._toDouble(json['lastPositionSeconds']),
      watchedSeconds: ViewerState._toDouble(json['watchedSeconds']),
      durationSeconds: ViewerState._toDouble(json['durationSeconds']),
      percent: ViewerState._toDouble(json['percent']).clamp(0.0, 1.0),
      completed: json['completed'] as bool? ?? false,
      completedAt: ViewerState._toDate(json['completedAt']),
      updatedAt: ViewerState._toDate(json['updatedAt']),
    );
  }
}
