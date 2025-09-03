import '../models/class_model.dart';

/// Enum representing the status of class-related operations.
enum ClassStatus { initial, loading, loaded, error }

/// State class for ClassCubit, holding status, list of classes, and error message.
class ClassState {
  final ClassStatus status;
  final List<ClassModel> classes;
  final String? error;

  const ClassState({
    this.status = ClassStatus.initial,
    this.classes = const [],
    this.error,
  });

  ClassState copyWith({
    ClassStatus? status,
    List<ClassModel>? classes,
    String? error,
  }) {
    return ClassState(
      status: status ?? this.status,
      classes: classes ?? this.classes,
      error: error,
    );
  }
} 