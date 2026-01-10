import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/class_model.dart';
import '../repository/class_repository.dart';
import 'class_states.dart';

class ClassCubit extends Cubit<ClassState> {
  final ClassRepository repository;
  ClassCubit(this.repository) : super(const ClassState());

  Future<void> fetchClasses() async {
    emit(state.copyWith(status: ClassStatus.loading));
    try {
      final classes = await repository.getClasses();
      emit(state.copyWith(status: ClassStatus.loaded, classes: classes, error: null));
    } catch (e) {
      // Extract user-friendly error message
      String errorMessage = 'Gagal memuatkan kelas';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      
      // For permission-denied errors, set error but don't trigger snackbars
      // The error will be shown in UI cards instead
      final isPermissionError = errorMessage.contains('permission-denied') ||
          errorMessage.contains('cloud_firestore') ||
          errorMessage.contains('Kebenaran ditolak') ||
          errorMessage.contains('Pengesahan diperlukan');
      
      emit(state.copyWith(
        status: ClassStatus.error, 
        error: errorMessage,
        // Store a flag to indicate this is a permission error (for UI handling)
      ));
    }
  }

  Future<void> addClass(ClassModel classModel) async {
    try {
      await repository.addClass(classModel);
      fetchClasses();
    } catch (e) {
      // Extract user-friendly error message
      String errorMessage = 'Gagal menambah kelas';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      emit(state.copyWith(status: ClassStatus.error, error: errorMessage));
    }
  }

  Future<void> updateClass(ClassModel classModel) async {
    try {
      await repository.updateClass(classModel);
      fetchClasses();
    } catch (e) {
      // Extract user-friendly error message
      String errorMessage = 'Gagal mengemas kini kelas';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      emit(state.copyWith(status: ClassStatus.error, error: errorMessage));
    }
  }

  Future<void> deleteClass(String id) async {
    try {
      await repository.deleteClass(id);
      fetchClasses();
    } catch (e) {
      // Extract user-friendly error message
      String errorMessage = 'Gagal memadam kelas';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      emit(state.copyWith(status: ClassStatus.error, error: errorMessage));
    }
  }
} 