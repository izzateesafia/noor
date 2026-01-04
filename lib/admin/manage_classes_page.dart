import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/class_model.dart';
import '../theme_constants.dart';
import '../cubit/class_cubit.dart';
import '../cubit/class_states.dart';
import '../repository/class_repository.dart';
import 'class_form_page.dart';
import 'class_students_page.dart';

class ManageClassesPage extends StatefulWidget {
  const ManageClassesPage({super.key});

  @override
  State<ManageClassesPage> createState() => _ManageClassesPageState();
}

class _ManageClassesPageState extends State<ManageClassesPage> {
  @override
  void initState() {
    super.initState();
    // Fetch classes when the page is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassCubit>().fetchClasses();
    });
  }

  void _addOrEditClass({ClassModel? classModel}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClassFormPage(
          initialClass: classModel,
          onSave: (newClass) {
            if (classModel != null) {
              context.read<ClassCubit>().updateClass(newClass);
            } else {
              context.read<ClassCubit>().addClass(newClass);
            }
          },
        ),
      ),
    );
    // Always fetch classes after returning from the form
    context.read<ClassCubit>().fetchClasses();
  }

  void _deleteClass(ClassModel classModel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Padam Kelas'),
        content: Text('Adakah anda pasti mahu memadam "${classModel.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Padam'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      context.read<ClassCubit>().deleteClass(classModel.id);
      // Fetch classes after deletion
      context.read<ClassCubit>().fetchClasses();
    }
  }

  void _duplicateClass(ClassModel classModel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salin Kelas'),
        content: Text('Adakah anda pasti mahu menyalin "${classModel.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Salin'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final duplicatedClass = ClassModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // New ID
        title: '${classModel.title} (Copy)',
        instructor: classModel.instructor,
        time: classModel.time,
        duration: classModel.duration,
        level: classModel.level,
        description: classModel.description,
        image: classModel.image,
        price: classModel.price,
        paymentUrl: classModel.paymentUrl,
        isHidden: classModel.isHidden,
      );
      
      try {
        context.read<ClassCubit>().addClass(duplicatedClass);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kelas "${classModel.title}" telah disalin'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ralat menyalin kelas: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  void _toggleHideClass(ClassModel classModel) async {
    try {
      context.read<ClassCubit>().updateClass(
        classModel.copyWith(isHidden: !classModel.isHidden),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(classModel.isHidden 
              ? 'Kelas telah ditunjukkan kepada pengguna'
              : 'Kelas telah disembunyikan daripada pengguna'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat mengemas kini kelas: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClassCubit, ClassState>(
      listener: (context, state) {
        if (state.status == ClassStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ralat: ${state.error}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (state.status == ClassStatus.loaded && state.classes.isNotEmpty) {
          // Optionally show a success snackbar after add/delete
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text('Class list updated!')),
          // );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Urus Kelas'),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            actions: [
              if (state.status == ClassStatus.loading)
                 Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Tambah Kelas',
                onPressed: state.status == ClassStatus.loading ? null : () => _addOrEditClass(),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(ClassState state) {
    switch (state.status) {
      case ClassStatus.initial:
      case ClassStatus.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading classes...'),
            ],
          ),
        );
      
      case ClassStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Error loading classes'),
              const SizedBox(height: 8),
              Text(
                state.error ?? 'Unknown error',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<ClassCubit>().fetchClasses(),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      
      case ClassStatus.loaded:
        if (state.classes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.class_, size: 64, color: AppColors.primary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No classes found',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first class using the + button',
                  style: TextStyle(
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          itemCount: state.classes.length,
          itemBuilder: (context, index) {
            final classModel = state.classes[index];
            return Opacity(
              opacity: classModel.isHidden ? 0.6 : 1.0,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.only(bottom: 18),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ClassStudentsPage(classModel: classModel),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        classModel.image != null && classModel.image!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: classModel.image!.startsWith('http://') || classModel.image!.startsWith('https://')
                                    ? Image.network(
                                        classModel.image!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.class_, color: Theme.of(context).colorScheme.primary, size: 40),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Image.asset(
                                        classModel.image!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.class_, color: Theme.of(context).colorScheme.primary, size: 40),
                                          );
                                        },
                                      ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.class_, color: Theme.of(context).colorScheme.primary, size: 40),
                              ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      classModel.title,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (classModel.isHidden)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Disembunyikan',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Instructor: ${classModel.instructor}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Price: RM ${classModel.price.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _addOrEditClass(classModel: classModel);
                                break;
                              case 'duplicate':
                                _duplicateClass(classModel);
                                break;
                              case 'hide':
                                _toggleHideClass(classModel);
                                break;
                              case 'delete':
                                _deleteClass(classModel);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, color: Colors.orange, size: 20),
                                  const SizedBox(width: 12),
                                  const Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'duplicate',
                              child: Row(
                                children: [
                                  const Icon(Icons.copy, color: Colors.blue, size: 20),
                                  const SizedBox(width: 12),
                                  const Text('Duplicate'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'hide',
                              child: Row(
                                children: [
                                  Icon(
                                    classModel.isHidden ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(classModel.isHidden ? 'Tunjukkan' : 'Sembunyikan'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Padam'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
    }
  }
} 