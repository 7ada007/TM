import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'api_client.dart';

String friendlyNetworkError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاتصال بالخادم. يرجى المحاولة لاحقاً';
      case DioExceptionType.connectionError:
        return 'تعذّر الاتصال بالخادم. تحقّق من اتصال الإنترنت';
      default:
        final status = error.response?.statusCode;
        if (status == 401 || status == 403) {
          return 'غير مصرح لك بتنفيذ هذا الإجراء';
        }
        if (status == 404) {
          return 'العنصر المطلوب غير موجود';
        }
        return 'حدث خطأ أثناء الاتصال بالخادم. يرجى المحاولة لاحقاً';
    }
  }
  return 'حدث خطأ غير متوقع. يرجى المحاولة لاحقاً';
}

List<Map<String, dynamic>> asJsonList(dynamic data) {
  if (data is! List) return const [];
  return data.whereType<Map<String, dynamic>>().toList();
}

Future<StreamInfo> resolveLectureStream(String videoPath) async {
  try {
    final response = await ApiClient.dio.get(
      '/stream',
      queryParameters: {'src': videoPath},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StreamInfo.fromJson(data);
    }
    return StreamInfo.progressive(videoPath);
  } catch (_) {
    return StreamInfo.progressive(videoPath);
  }
}

class ApiDataService extends ChangeNotifier {
  List<UserModel> _users = [];
  List<LectureModel> _lectures = [];
  final List<TeacherAssignment> _teacherAssignments = [];
  List<CommentModel> _comments = [];
  List<LectureRatingModel> _lectureRatings = [];
  List<AttendanceRecordModel> _attendanceRecords = [];
  List<CommunityPostModel> _communityPosts = [];
  final Map<String, List<CommunityCommentModel>> _communityComments = {};

  List<UserModel> get users => List.unmodifiable(_users);
  List<UserModel> getAllUsers() => List.unmodifiable(_users);
  List<LectureModel> get lectures => List.unmodifiable(_lectures);
  List<TeacherAssignment> get teacherAssignments =>
      List.unmodifiable(_teacherAssignments);
  List<CommentModel> get comments => List.unmodifiable(_comments);
  List<LectureRatingModel> get lectureRatings =>
      List.unmodifiable(_lectureRatings);
  List<AttendanceRecordModel> get attendanceRecords =>
      List.unmodifiable(_attendanceRecords);

  List<CommunityPostModel> get communityPosts {
    final sorted = List<CommunityPostModel>.from(_communityPosts)
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    return List.unmodifiable(sorted);
  }

  List<UserModel> get students =>
      _users.where((u) => u.role == UserRole.student).toList();
  List<UserModel> get teachers =>
      _users.where((u) => u.role == UserRole.teacher).toList();
  List<UserModel> get admins =>
      _users.where((u) => u.role == UserRole.admin).toList();
  List<UserModel> getAllAdmins() => admins;

  Future<void> initialize() async {
    await fetchAllData();
  }

  Future<void> fetchAllData() async {
    try {
      await refreshAll();
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  Future<void> refreshAll() async {
    final responses = await Future.wait([
      ApiClient.dio.get('/users'),
      ApiClient.dio.get('/lectures'),
      ApiClient.dio.get('/attendance'),
      ApiClient.dio.get('/comments'),
      ApiClient.dio.get('/ratings'),
      ApiClient.dio.get('/community/posts'),
    ]);

    _users = asJsonList(responses[0].data).map(UserModel.fromJson).toList();
    _lectures = asJsonList(
      responses[1].data,
    ).map(LectureModel.fromJson).toList();
    _attendanceRecords = asJsonList(
      responses[2].data,
    ).map(AttendanceRecordModel.fromJson).toList();
    _comments = asJsonList(
      responses[3].data,
    ).map(CommentModel.fromJson).toList();
    _lectureRatings = asJsonList(
      responses[4].data,
    ).map(LectureRatingModel.fromJson).toList();
    _communityPosts = asJsonList(
      responses[5].data,
    ).map(CommunityPostModel.fromJson).toList();

    notifyListeners();
  }

  UserModel? findUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  List<UserModel> getTeachersForSubject(String subject) {
    return _users
        .where(
          (u) => u.role == UserRole.teacher && u.subjects.contains(subject),
        )
        .toList();
  }

  String getTeachersDisplayForSubject(String subject) {
    final teachersList = getTeachersForSubject(subject);
    if (teachersList.isEmpty) return 'لم يُعيَّن بعد';
    return teachersList.map((t) => t.name).join(' • ');
  }

  Future<void> addStudent(UserModel student) async {
    try {
      await ApiClient.dio.post('/users', data: student.toJson());
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
    _users.add(student);
    notifyListeners();
  }

  Future<void> updateStudent(UserModel updated) async {
    await updateUser(updated);
  }

  Future<String?> deleteStudent(String userId) async {
    return await deleteUser(userId);
  }

  Future<void> addTeacher(UserModel teacher) async {
    try {
      await ApiClient.dio.post('/users', data: teacher.toJson());
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
    _users.add(teacher);
    notifyListeners();
  }

  Future<void> updateTeacher(UserModel updated) async {
    await updateUser(updated);
  }

  Future<String?> deleteTeacher(String userId) async {
    return await deleteUser(userId);
  }

  Future<void> updateUser(UserModel updated) async {
    try {
      await ApiClient.dio.put('/users/${updated.id}', data: updated.toJson());
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
    final index = _users.indexWhere((u) => u.id == updated.id);
    if (index != -1) {
      _users[index] = updated;
      notifyListeners();
    }
  }

  Future<String?> deleteUser(String userId) async {
    try {
      await ApiClient.dio.delete('/users/$userId');
      _users.removeWhere((u) => u.id == userId);
      notifyListeners();
      return null;
    } catch (e) {
      return friendlyNetworkError(e);
    }
  }

  bool isUsernameTaken(String username, {String? excludeUserId}) {
    return _users.any(
      (u) =>
          u.username.toLowerCase() == username.toLowerCase() &&
          u.id != excludeUserId,
    );
  }

  Future<String?> promoteToAdmin(String userId) async {
    final user = findUserById(userId);
    if (user == null) return 'المستخدم غير موجود';
    if (user.role == UserRole.admin) return 'المستخدم مشرف بالفعل';
    user.role = UserRole.admin;
    await updateUser(user);
    return null;
  }

  Future<void> assignTeacherRole(String userId) async {
    final user = findUserById(userId);
    if (user != null) {
      user.role = UserRole.teacher;
      await updateUser(user);
    }
  }

  Future<void> assignStudentRole(String userId) async {
    final user = findUserById(userId);
    if (user != null) {
      user.role = UserRole.student;
      await updateUser(user);
    }
  }

  Future<void> updateAdmin(UserModel updated) async {
    await updateUser(updated);
  }

  Future<String?> deleteAdmin(String userId) async {
    return await deleteUser(userId);
  }

  Future<void> addLecture(LectureModel lecture) async {
    try {
      await ApiClient.dio.post('/lectures', data: lecture.toJson());
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
    _lectures.add(lecture);
    notifyListeners();
  }

  Future<void> updateLecture(LectureModel lecture) async {
    try {
      await ApiClient.dio.put(
        '/lectures/${lecture.id}',
        data: lecture.toJson(),
      );
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
    final index = _lectures.indexWhere((l) => l.id == lecture.id);
    if (index != -1) {
      _lectures[index] = lecture;
      notifyListeners();
    }
  }

  Future<void> deleteLecture(String lectureId) async {
    try {
      await ApiClient.dio.delete('/lectures/$lectureId');
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
    _lectures.removeWhere((l) => l.id == lectureId);
    notifyListeners();
  }

  Future<void> toggleLectureFavorite(String lectureId, [String? userId]) async {
    final idx = _lectures.indexWhere((l) => l.id == lectureId);
    if (idx != -1) {
      _lectures[idx].isFavorite = !_lectures[idx].isFavorite;
      notifyListeners();
    }
  }

  Future<void> toggleLecturePublishStatus(String lectureId) async {
    final idx = _lectures.indexWhere((l) => l.id == lectureId);
    if (idx == -1) return;
    _lectures[idx].isPublished = !_lectures[idx].isPublished;
    try {
      await ApiClient.dio.put(
        '/lectures/${_lectures[idx].id}',
        data: _lectures[idx].toJson(),
      );
    } on DioException catch (e) {
      _lectures[idx].isPublished = !_lectures[idx].isPublished;
      throw Exception(friendlyNetworkError(e));
    }
    notifyListeners();
  }

  Future<void> updateLectureDuration(String lectureId, String duration) async {
    final idx = _lectures.indexWhere((l) => l.id == lectureId);
    if (idx == -1) return;
    final previousDuration = _lectures[idx].duration;
    _lectures[idx].duration = duration;
    try {
      await ApiClient.dio.put(
        '/lectures/${_lectures[idx].id}',
        data: _lectures[idx].toJson(),
      );
    } on DioException catch (e) {
      _lectures[idx].duration = previousDuration;
      throw Exception(friendlyNetworkError(e));
    }
    notifyListeners();
  }

  List<LectureModel> getLecturesForStudent({
    required List<String> subjects,
    required String section,
  }) {
    return _lectures
        .where(
          (l) =>
              l.isPublished &&
              subjects.contains(l.subject) &&
              (l.section == 'الكل' || l.section == section),
        )
        .toList();
  }

  List<LectureModel> getLecturesForTeacher(String teacherId) {
    return _lectures.where((l) => l.teacherId == teacherId).toList();
  }

  Future<void> recordAttendance({
    required String studentId,
    required String section,
    required String subject,
    required DateTime date,
    required AttendanceStatus status,
    required String recordedBy,
    required String recordedByName,
  }) async {
    final record = AttendanceRecordModel(
      id: const Uuid().v4(),
      studentId: studentId,
      studentName: findUserById(studentId)?.name ?? '',
      section: section,
      subject: subject,
      date: date,
      status: status,
      recordedBy: recordedBy,
      recordedByName: recordedByName,
      recordedAt: DateTime.now(),
    );
    try {
      await ApiClient.dio.post('/attendance', data: record.toJson());
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
    _attendanceRecords.add(record);
    notifyListeners();
  }

  Future<void> updateAttendance(AttendanceRecordModel record) async {
    try {
      await ApiClient.dio.put(
        '/attendance/${record.id}',
        data: record.toJson(),
      );
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
    final idx = _attendanceRecords.indexWhere((r) => r.id == record.id);
    if (idx != -1) {
      _attendanceRecords[idx] = record;
      notifyListeners();
    }
  }

  Future<void> addComment(CommentModel comment) async {
    try {
      await ApiClient.dio.post('/comments', data: comment.toJson());
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
    _comments.add(comment);
    notifyListeners();
  }

  Future<void> deleteLectureComment(String commentId) async {
    try {
      await ApiClient.dio.delete('/comments/$commentId');
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
    _comments.removeWhere((c) => c.id == commentId);
    notifyListeners();
  }

  Future<void> setLectureRating(LectureRatingModel rating) async {
    try {
      await ApiClient.dio.post('/ratings', data: rating.toJson());
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
    final idx = _lectureRatings.indexWhere(
      (r) => r.lectureId == rating.lectureId && r.userId == rating.userId,
    );
    if (idx != -1) {
      _lectureRatings[idx] = rating;
    } else {
      _lectureRatings.add(rating);
    }
    notifyListeners();
  }

  LectureRatingSummary getLectureRatingSummary(
    String lectureId,
    String? currentUserId,
  ) {
    final ratings = _lectureRatings
        .where((r) => r.lectureId == lectureId)
        .toList();
    if (ratings.isEmpty) {
      return const LectureRatingSummary(average: 0.0, count: 0);
    }

    double sum = 0;
    int? userStars;
    for (var r in ratings) {
      sum += r.stars;
      if (currentUserId != null && r.userId == currentUserId) {
        userStars = r.stars;
      }
    }
    return LectureRatingSummary(
      average: sum / ratings.length,
      count: ratings.length,
      userStars: userStars,
    );
  }

  List<CommentModel> getCommentsForLecture(String lectureId) {
    return _comments.where((c) => c.lectureId == lectureId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> assignTeacherToSubject(String teacherId, String subject) async {
    final user = findUserById(teacherId);
    if (user != null && !user.subjects.contains(subject)) {
      user.subjects.add(subject);
      await updateUser(user);
    }
  }

  Future<void> unassignTeacherFromSubject(
    String teacherId,
    String subject,
  ) async {
    final user = findUserById(teacherId);
    if (user != null) {
      user.subjects.remove(subject);
      await updateUser(user);
    }
  }

  Future<void> refreshCommunityPosts() async {
    try {
      final response = await ApiClient.dio.get('/community/posts');
      _communityPosts = asJsonList(
        response.data,
      ).map(CommunityPostModel.fromJson).toList();
      notifyListeners();
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
  }

  Future<CommunityPostModel> createCommunityPost({
    String? title,
    required String content,
    String? imagePath,
    String? videoPath,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/community/posts',
        data: {
          'title': title,
          'content': content,
          'imagePath': imagePath,
          'videoPath': videoPath,
        },
      );
      final post = CommunityPostModel.fromJson(response.data);
      _communityPosts.insert(0, post);
      notifyListeners();
      return post;
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
  }

  Future<void> updateCommunityPost(CommunityPostModel post) async {
    try {
      final response = await ApiClient.dio.put(
        '/community/posts/${post.id}',
        data: post.toJson(),
      );
      final updated = CommunityPostModel.fromJson(response.data);
      final idx = _communityPosts.indexWhere((p) => p.id == post.id);
      if (idx != -1) _communityPosts[idx] = updated;
      notifyListeners();
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
  }

  Future<void> deleteCommunityPost(String postId) async {
    try {
      await ApiClient.dio.delete('/community/posts/$postId');
      _communityPosts.removeWhere((p) => p.id == postId);
      _communityComments.remove(postId);
      notifyListeners();
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
  }

  Future<void> toggleCommunityPostPin(String postId) async {
    try {
      final response = await ApiClient.dio.post('/community/posts/$postId/pin');
      final updated = CommunityPostModel.fromJson(response.data);
      final idx = _communityPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) _communityPosts[idx] = updated;
      notifyListeners();
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
  }

  List<CommunityCommentModel> getCommunityComments(String postId) =>
      List.unmodifiable(_communityComments[postId] ?? const []);

  Future<void> fetchCommunityComments(String postId) async {
    try {
      final response = await ApiClient.dio.get(
        '/community/posts/$postId/comments',
      );
      _communityComments[postId] = asJsonList(
        response.data,
      ).map(CommunityCommentModel.fromJson).toList();
      notifyListeners();
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
  }

  Future<void> addCommunityComment({
    required String postId,
    required String content,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/community/posts/$postId/comments',
        data: {'content': content},
      );
      final comment = CommunityCommentModel.fromJson(response.data);
      _communityComments.putIfAbsent(postId, () => []).add(comment);
      final idx = _communityPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) _communityPosts[idx].commentCount += 1;
      notifyListeners();
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
  }

  Future<void> deleteCommunityComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      await ApiClient.dio.delete(
        '/community/posts/$postId/comments/$commentId',
      );
      _communityComments[postId]?.removeWhere((c) => c.id == commentId);
      final idx = _communityPosts.indexWhere((p) => p.id == postId);
      if (idx != -1 && _communityPosts[idx].commentCount > 0) {
        _communityPosts[idx].commentCount -= 1;
      }
      notifyListeners();
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
  }

  Future<void> reportCommunityPost({
    required String postId,
    String? reason,
  }) async {
    try {
      await ApiClient.dio.post(
        '/community/posts/$postId/report',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
  }
}
