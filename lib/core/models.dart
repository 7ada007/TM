enum AttendanceStatus { present, absent, excused }

class AttendanceRecordModel {
  final String id;
  final String studentId;
  final String studentName;
  final String section;
  final String? subject;
  final DateTime date;
  AttendanceStatus status;
  final String recordedBy;
  final String recordedByName;
  final DateTime recordedAt;

  AttendanceRecordModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.section,
    this.subject,
    required this.date,
    required this.status,
    required this.recordedBy,
    required this.recordedByName,
    required this.recordedAt,
  });

  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String get statusLabel => switch (status) {
    AttendanceStatus.present => 'حضور',
    AttendanceStatus.absent => 'لم يحضر',
    AttendanceStatus.excused => 'مجاز',
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'section': section,
    'subject': subject,
    'date': date.toUtc().toIso8601String(),
    'status': status.name,
    'recordedBy': recordedBy,
    'recordedByName': recordedByName,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
  };

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) =>
      AttendanceRecordModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String,
        section: json['section'] as String,
        subject: json['subject'] as String?,
        date: DateTime.parse(json['date'] as String),
        status: AttendanceStatus.values.byName(json['status'] as String),
        recordedBy: json['recordedBy'] as String,
        recordedByName: json['recordedByName'] as String,
        recordedAt: DateTime.parse(json['recordedAt'] as String),
      );

  AttendanceRecordModel copyWith({AttendanceStatus? status}) {
    return AttendanceRecordModel(
      id: id,
      studentId: studentId,
      studentName: studentName,
      section: section,
      subject: subject,
      date: date,
      status: status ?? this.status,
      recordedBy: recordedBy,
      recordedByName: recordedByName,
      recordedAt: recordedAt,
    );
  }
}

class CommentModel {
  final String id;
  final String lectureId;
  final String userId;
  final String userName;
  final String? userPhotoPath;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.lectureId,
    required this.userId,
    required this.userName,
    this.userPhotoPath,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'lectureId': lectureId,
    'userId': userId,
    'userName': userName,
    'userPhotoPath': userPhotoPath,
    'content': content,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
    id: json['id'] as String,
    lectureId: json['lectureId'] as String,
    userId: json['userId'] as String,
    userName: json['userName'] as String,
    userPhotoPath: json['userPhotoPath'] as String?,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class LectureModel {
  final String id;
  String title;
  String description;
  String subject;
  String section;
  String teacherId;
  String teacherName;
  String videoPath;
  String? coverImagePath;
  String date;
  String? publishedAt;
  String? duration;
  int fileSizeBytes;
  bool isFavorite;
  bool isPublished;

  LectureModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.subject,
    this.section = 'شعبة أ',
    required this.teacherId,
    required this.teacherName,
    required this.videoPath,
    this.coverImagePath,
    required this.date,
    this.publishedAt,
    this.duration,
    this.fileSizeBytes = 0,
    this.isFavorite = false,
    this.isPublished = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'subject': subject,
    'section': section,
    'teacherId': teacherId,
    'teacherName': teacherName,
    'videoPath': videoPath,
    'coverImagePath': coverImagePath,
    'date': date,
    'publishedAt': publishedAt,
    'duration': duration,
    'fileSizeBytes': fileSizeBytes,
    'isFavorite': isFavorite,
    'isPublished': isPublished,
  };

  factory LectureModel.fromJson(Map<String, dynamic> json) => LectureModel(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    subject: json['subject'] as String,
    section: json['section'] as String? ?? 'شعبة أ',
    teacherId: json['teacherId'] as String,
    teacherName: json['teacherName'] as String,
    videoPath: json['videoPath'] as String,
    coverImagePath: json['coverImagePath'] as String?,
    date: json['date'] as String,
    publishedAt: json['publishedAt'] as String?,
    duration: json['duration'] as String?,
    fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
    isFavorite: json['isFavorite'] as bool? ?? false,
    isPublished: json['isPublished'] as bool? ?? true,
  );
}

class LectureRatingModel {
  final String id;
  final String lectureId;
  final String userId;
  final int stars;
  final DateTime createdAt;

  LectureRatingModel({
    required this.id,
    required this.lectureId,
    required this.userId,
    required this.stars,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'lectureId': lectureId,
    'userId': userId,
    'stars': stars,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory LectureRatingModel.fromJson(Map<String, dynamic> json) =>
      LectureRatingModel(
        id: json['id'] as String,
        lectureId: json['lectureId'] as String,
        userId: json['userId'] as String,
        stars: json['stars'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class LectureRatingSummary {
  final double average;
  final int count;
  final int? userStars;

  const LectureRatingSummary({
    required this.average,
    required this.count,
    this.userStars,
  });
}

class CommunityPostModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoPath;
  String? title;
  String content;
  String? imagePath;
  String? videoPath;
  bool isPinned;
  final DateTime createdAt;
  DateTime? updatedAt;
  int commentCount;

  CommunityPostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoPath,
    this.title,
    required this.content,
    this.imagePath,
    this.videoPath,
    this.isPinned = false,
    required this.createdAt,
    this.updatedAt,
    this.commentCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'imagePath': imagePath,
    'videoPath': videoPath,
  };

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) =>
      CommunityPostModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        userPhotoPath: json['userPhotoPath'] as String?,
        title: json['title'] as String?,
        content: json['content'] as String? ?? '',
        imagePath: json['imagePath'] as String?,
        videoPath: json['videoPath'] as String?,
        isPinned: json['isPinned'] as bool? ?? false,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
        commentCount: json['commentCount'] as int? ?? 0,
      );
}

class CommunityCommentModel {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userPhotoPath;
  final String content;
  final DateTime createdAt;

  CommunityCommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userPhotoPath,
    required this.content,
    required this.createdAt,
  });

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) =>
      CommunityCommentModel(
        id: json['id'] as String,
        postId: json['postId'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        userPhotoPath: json['userPhotoPath'] as String?,
        content: json['content'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class TeacherAssignment {
  final String id;
  String teacherId;
  String subject;

  TeacherAssignment({
    required this.id,
    required this.teacherId,
    required this.subject,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'teacherId': teacherId,
    'subject': subject,
  };

  factory TeacherAssignment.fromJson(Map<String, dynamic> json) =>
      TeacherAssignment(
        id: json['id'] as String,
        teacherId: json['teacherId'] as String,
        subject: json['subject'] as String,
      );
}

class StreamVariant {
  final int height;
  final String name;
  final String playlist;

  const StreamVariant({
    required this.height,
    required this.name,
    required this.playlist,
  });

  factory StreamVariant.fromJson(Map<String, dynamic> json) => StreamVariant(
    height: json['height'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    playlist: json['playlist'] as String? ?? '',
  );
}

class StreamInfo {
  final String state;
  final String play;
  final String? hls;
  final String progressive;
  final List<StreamVariant> variants;
  final bool adaptive;

  const StreamInfo({
    required this.state,
    required this.play,
    this.hls,
    required this.progressive,
    this.variants = const [],
    this.adaptive = false,
  });

  bool get isReady => state == 'ready';

  factory StreamInfo.progressive(String path) =>
      StreamInfo(state: 'none', play: path, progressive: path);

  factory StreamInfo.fromJson(Map<String, dynamic> json) => StreamInfo(
    state: json['state'] as String? ?? 'none',
    play:
        json['play'] as String? ??
        (json['progressive'] as String? ?? ''),
    hls: json['hls'] as String?,
    progressive: json['progressive'] as String? ?? '',
    variants:
        (json['variants'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(StreamVariant.fromJson)
            .toList() ??
        const [],
    adaptive: json['adaptive'] as bool? ?? false,
  );
}

enum UserRole { student, teacher, admin }

class UserModel {
  final String id;
  String name;
  String username;
  String password;
  String? email;
  String? phone;
  String? section;
  String? guardianName;
  String? guardianPhone;
  String gender;
  List<String> subjects;
  String? notes;
  String? photoPath;
  String? schoolName;
  DateTime? lastNameChangeAt;
  UserRole role;
  bool get isSuperAdmin => id == 'admin-1' && role == UserRole.admin;
  bool canUploadLectures;
  DateTime createdAt;

  String get localizedRole {
    if (isSuperAdmin) return 'المدير الأساسي';
    if (role == UserRole.admin) return 'مشرف النظام';
    if (role == UserRole.teacher) return 'أستاذ';
    if (role == UserRole.student) {
      return gender == 'ذكر' ? 'طالب' : 'طالبة';
    }
    return '';
  }

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    this.email,
    this.phone,
    this.section,
    this.guardianName,
    this.guardianPhone,
    this.gender = 'ذكر',
    this.subjects = const [],
    this.notes,
    this.photoPath,
    this.schoolName,
    this.lastNameChangeAt,
    required this.role,
    this.canUploadLectures = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'password': password,
    'email': email,
    'phone': phone,
    'section': section,
    'guardianName': guardianName,
    'guardianPhone': guardianPhone,
    'gender': gender,
    'subjects': subjects,
    'notes': notes,
    'photoPath': photoPath,
    'schoolName': schoolName,
    'lastNameChangeAt': lastNameChangeAt?.toUtc().toIso8601String(),
    'role': role.name,
    'canUploadLectures': canUploadLectures,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String,
    username: json['username'] as String,
    password: json['password'] as String? ?? '',
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    section: json['section'] as String?,
    guardianName: json['guardianName'] as String?,
    guardianPhone: json['guardianPhone'] as String?,
    gender: json['gender'] as String? ?? 'ذكر',
    subjects: List<String>.from(json['subjects'] ?? []),
    notes: json['notes'] as String?,
    photoPath: json['photoPath'] as String?,
    schoolName: json['schoolName'] as String?,
    lastNameChangeAt: json['lastNameChangeAt'] != null
        ? DateTime.tryParse(json['lastNameChangeAt'] as String)
        : null,
    role: UserRole.values.byName(json['role'] as String),
    canUploadLectures: json['canUploadLectures'] as bool? ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );

  UserModel copyWith({
    String? name,
    String? username,
    String? password,
    String? email,
    String? phone,
    String? section,
    String? guardianName,
    String? guardianPhone,
    String? gender,
    List<String>? subjects,
    String? notes,
    String? photoPath,
    String? schoolName,
    DateTime? lastNameChangeAt,
    UserRole? role,
    bool? canUploadLectures,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      section: section ?? this.section,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      gender: gender ?? this.gender,
      subjects: subjects ?? this.subjects,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      schoolName: schoolName ?? this.schoolName,
      lastNameChangeAt: lastNameChangeAt ?? this.lastNameChangeAt,
      role: role ?? this.role,
      canUploadLectures: canUploadLectures ?? this.canUploadLectures,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get registrationDateLabel =>
      '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
}
