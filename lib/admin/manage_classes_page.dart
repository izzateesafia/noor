import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/class_model.dart';
import '../theme_constants.dart';
import '../cubit/class_cubit.dart';
import '../cubit/class_states.dart';
import '../repository/class_repository.dart';
import 'class_form_page.dart';

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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClassCubit, ClassState>(
      listener: (context, state) {
        if (state.status == ClassStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ralat: ${state.error}'),
              backgroundColor: Colors.red,
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
            title: const Text('Manage Classes'),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            actions: [
              if (state.status == ClassStatus.loading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: _buildBody(state),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: state.status == ClassStatus.loading ? null : () => _addOrEditClass(),
            icon: const Icon(Icons.add),
            label: const Text('Add Class'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
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
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading classes'),
              const SizedBox(height: 8),
              Text(state.error ?? 'Unknown error', style: TextStyle(color: Colors.red)),
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
            return Slidable(
              key: ValueKey(classModel.id),
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) => _addOrEditClass(classModel: classModel),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Edit',
                  ),
                  SlidableAction(
                    onPressed: (context) => _deleteClass(classModel),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Delete',
                  ),
                ],
              ),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.only(bottom: 18),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: classModel.image != null && classModel.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            classModel.image!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.class_, color: Theme.of(context).colorScheme.primary, size: 30),
                              );
                            },
                          ),
                        )
                      : Icon(Icons.class_, color: Theme.of(context).colorScheme.primary, size: 40),
                  title: Text(
                    classModel.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    'Instructor: ${classModel.instructor}\nPrice: RM ${classModel.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                      fontSize: 13,
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