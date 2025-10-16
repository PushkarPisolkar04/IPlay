import 'package:flutter/foundation.dart';
import '../models/classroom_model.dart';
import '../services/firestore_service.dart';

class ClassroomProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  final List<ClassroomModel> _classrooms = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ClassroomModel> get classrooms => _classrooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<ClassroomModel?> createClassroom({
    required String teacherId,
    required String teacherName,
    required String name,
    required int grade,
    String? school,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final classroom = await _firestoreService.createClassroom(
        teacherId: teacherId,
        teacherName: teacherName,
        name: name,
        grade: grade,
        school: school,
      );

      return classroom;
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Create classroom error: $e');
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ClassroomModel?> joinClassroom(String classCode, String studentId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final classroom = await _firestoreService.joinClassroom(classCode, studentId);
      return classroom;
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Join classroom error: $e');
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveStudent(String classroomId, String studentId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.approveStudent(classroomId, studentId);
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Approve student error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<ClassroomModel>> getTeacherClassrooms(String teacherId) {
    return _firestoreService.getTeacherClassrooms(teacherId);
  }

  Stream<List<ClassroomModel>> getStudentClassrooms(List<String> classroomIds) {
    return _firestoreService.getStudentClassrooms(classroomIds);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

