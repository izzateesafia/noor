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
      emit(state.copyWith(status: ClassStatus.loaded, classes: classes));
    } catch (e) {
      emit(state.copyWith(status: ClassStatus.error, error: e.toString()));
    }
  }

  Future<void> addClass(ClassModel classModel) async {
    try {
      await repository.addClass(classModel);
      fetchClasses();
    } catch (e) {
      emit(state.copyWith(status: ClassStatus.error, error: e.toString()));
    }
  }

  Future<void> updateClass(ClassModel classModel) async {
    try {
      await repository.updateClass(classModel);
      fetchClasses();
    } catch (e) {
      emit(state.copyWith(status: ClassStatus.error, error: e.toString()));
    }
  }

  Future<void> deleteClass(String id) async {
    try {
      await repository.deleteClass(id);
      fetchClasses();
    } catch (e) {
      emit(state.copyWith(status: ClassStatus.error, error: e.toString()));
    }
  }
} 