import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'services.dart';
import 'api_client.dart';
import 'chunked_uploader.dart';
import 'core.dart' show PermissionUtils;

String cleanErrorMessage(Object error) {
  return error.toString().replaceFirst('Exception: ', '').trim();
}

extension ApiDataServiceExtensions on ApiDataService {
  Future<String?> resetUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      await ApiClient.dio.put(
        '/users/$userId/password',
        data: {'newPassword': newPassword},
      );
      return null;
    } on DioException catch (e) {
      return friendlyNetworkError(e);
    } catch (e) {
      return cleanErrorMessage(e);
    }
  }

  LectureModel? findLectureById(String id) {
    try {
      return lectures.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CommentModel> getCommentsByUser(String userId) {
    return comments.where((c) => c.userId == userId).toList();
  }

  Future<String?> saveProfilePhoto(
    File file,
    String userId, {
    void Function(double progress)? onProgress,
  }) async {
    final user = findUserById(userId);
    if (user == null) return null;

    final String remoteUrl;
    try {
      remoteUrl = await ApiClient.uploadFile(file, onProgress: onProgress);
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }

    user.photoPath = remoteUrl;
    await updateUser(user);
    return remoteUrl;
  }

  Future<void> removeProfilePhoto(String userId) async {
    final user = findUserById(userId);
    if (user == null) return;
    user.photoPath = null;
    await updateUser(user);
  }

  Future<String?> updateUserSafely({
    required UserModel updated,
    UserModel? actor,
  }) async {
    try {
      await updateUser(updated);
      return null;
    } catch (e) {
      return cleanErrorMessage(e);
    }
  }

  Future<void> setTeacherUploadPermission(
    String teacherId,
    bool canUpload,
  ) async {
    final user = findUserById(teacherId);
    if (user != null) {
      user.canUploadLectures = canUpload;
      await updateUser(user);
    }
  }

  Future<void> removeTeacherFromSubject(
    String teacherId,
    String subject,
  ) async {
    final user = findUserById(teacherId);
    if (user != null) {
      user.subjects.remove(subject);
      await updateUser(user);
    }
  }

  Future<String?> deleteUserData({
    required String userId,
    UserModel? actor,
  }) async {
    try {
      final target = findUserById(userId);
      if (target == null) return 'المستخدم غير موجود';

      if (!PermissionUtils.canDeleteUser(actor: actor, target: target)) {
        return 'غير مصرح';
      }
      await deleteUser(userId);
      return null;
    } catch (e) {
      return cleanErrorMessage(e);
    }
  }

  double getAverageRating(String lectureId) {
    return getLectureRatingSummary(lectureId, null).average;
  }

  int getRatingCount(String lectureId) {
    return getLectureRatingSummary(lectureId, null).count;
  }

  LectureRatingSummary getRatingSummary({
    required String lectureId,
    String? userId,
  }) {
    return getLectureRatingSummary(lectureId, userId);
  }

  Future<void> setLectureRatingData({
    required String lectureId,
    required String userId,
    required int stars,
  }) async {
    final rating = LectureRatingModel(
      id: const Uuid().v4(),
      lectureId: lectureId,
      userId: userId,
      stars: stars,
      createdAt: DateTime.now(),
    );
    await setLectureRating(rating);
  }

  Future<void> addRegistrationRequest(UserModel user) async {
    await addStudent(user);
  }

  List<String> getSubjectsForTeacher(String teacherId) {
    final t = findUserById(teacherId);
    return t?.subjects ?? [];
  }

  List<LectureModel> getLecturesForSubjectAndSection({
    required String subject,
    required String section,
  }) {
    return lectures
        .where(
          (l) =>
              l.subject == subject &&
              (l.section == section || l.section == 'الكل'),
        )
        .toList();
  }

  Map<String, int> getLectureCountsBySubject({
    List<String>? subjects,
    String? section,
  }) {
    final map = <String, int>{};
    for (var l in lectures) {
      if (!l.isPublished) continue;
      if (subjects != null && !subjects.contains(l.subject)) continue;
      if (section != null && l.section != section) continue;
      map[l.subject] = (map[l.subject] ?? 0) + 1;
    }
    return map;
  }

  List<LectureModel> getLecturesForStudentData({
    required List<String> subjects,
    required String section,
  }) {
    return lectures
        .where(
          (l) =>
              l.isPublished &&
              subjects.contains(l.subject) &&
              (l.section == 'الكل' || l.section == section),
        )
        .toList();
  }

  Future<void> addCommentData({
    required String lectureId,
    required String userId,
    required String userName,
    String? userPhotoPath,
    required String content,
  }) async {
    final comment = CommentModel(
      id: const Uuid().v4(),
      lectureId: lectureId,
      userId: userId,
      userName: userName,
      userPhotoPath: userPhotoPath,
      content: content,
      createdAt: DateTime.now(),
    );
    await addComment(comment);
  }

  Future<void> addLectureData({
    required String title,
    required String description,
    required String subject,
    required String section,
    required String teacherId,
    required File videoFile,
    File? coverImageFile,
    void Function(double)? onUploadProgress,
  }) async {
    final fileSize = await videoFile.length();
    final hasCover = coverImageFile != null;

    const coverWeight = 0.10;
    final videoWeight = hasCover ? 1 - coverWeight : 1.0;

    String? coverUrl;
    try {
      if (coverImageFile != null) {
        coverUrl = await ChunkedUploader.upload(coverImageFile);
        onUploadProgress?.call(coverWeight);
      }

      final videoUrl = await ChunkedUploader.upload(
        videoFile,
        onProgress: (p) => onUploadProgress?.call(
          (hasCover ? coverWeight : 0) + p * videoWeight,
        ),
      );

      final lecture = LectureModel(
        id: const Uuid().v4(),
        title: title,
        description: description,
        subject: subject,
        section: section,
        teacherId: teacherId,
        teacherName: findUserById(teacherId)?.name ?? '',
        videoPath: videoUrl,
        coverImagePath: coverUrl,
        date: DateTime.now().toIso8601String(),
        publishedAt: DateTime.now().toIso8601String(),
        duration: '0:00',
        fileSizeBytes: fileSize,
        isPublished: true,
      );
      await addLecture(lecture);
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }
  }

  Future<void> updateLectureData({
    required String lectureId,
    required String title,
    required String date,
    required String subject,
    required String section,
    required String teacherId,
    File? videoFile,
    File? coverImageFile,
    void Function(double)? onUploadProgress,
  }) async {
    final lecture = findLectureById(lectureId);
    if (lecture == null) return;

    try {
      if (coverImageFile != null) {
        lecture.coverImagePath = await ChunkedUploader.upload(coverImageFile);
      }
      if (videoFile != null) {
        lecture.videoPath = await ChunkedUploader.upload(
          videoFile,
          onProgress: onUploadProgress,
        );
      }
    } on DioException catch (e) {
      throw Exception(friendlyNetworkError(e));
    }

    lecture.title = title;
    lecture.subject = subject;
    lecture.section = section;
    await updateLecture(lecture);
  }

  List<AttendanceRecordModel> getAttendanceRecords({
    String? section,
    String? query,
    String? recordedBy,
  }) {
    var records = attendanceRecords;

    if (section != null && section.isNotEmpty) {
      records = records.where((r) => r.section == section).toList();
    }

    if (recordedBy != null && recordedBy.isNotEmpty) {
      records = records.where((r) => r.recordedBy == recordedBy).toList();
    }

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      records = records
          .where((r) => r.studentName.toLowerCase().contains(q))
          .toList();
    }

    return records;
  }
}

class LecturePermissions {
  static bool canEdit(UserModel? user, LectureModel lecture) {
    if (user == null) return false;
    return user.role == UserRole.admin || user.id == lecture.teacherId;
  }

  static bool canDelete(UserModel? user, LectureModel lecture) {
    if (user == null) return false;
    return user.role == UserRole.admin || user.id == lecture.teacherId;
  }

  static bool canManageLecture({
    required AuthService auth,
    required LectureModel lecture,
  }) {
    return canEdit(auth.currentUser, lecture);
  }
}
