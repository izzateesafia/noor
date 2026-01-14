import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_states.dart';

class ClassStudentsPage extends StatefulWidget {
  final ClassModel classModel;

  const ClassStudentsPage({
    super.key,
    required this.classModel,
  });

  @override
  State<ClassStudentsPage> createState() => _ClassStudentsPageState();
}

class _ClassStudentsPageState extends State<ClassStudentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    // Fetch users when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserCubit>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _getEnrolledStudents(List<UserModel> allUsers) {
    return allUsers
        .where((user) => user.enrolledClassIds.contains(widget.classModel.id))
        .toList();
  }

  List<UserModel> _getAvailableStudents(List<UserModel> allUsers) {
    return allUsers
        .where((user) => !user.enrolledClassIds.contains(widget.classModel.id))
        .toList();
  }

  List<UserModel> _filterSearchResults(List<UserModel> availableStudents) {
    if (_searchQuery.isEmpty) return [];
    
    final query = _searchQuery.toLowerCase();
    return availableStudents.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          (user.phone != null && user.phone!.toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _addStudentToClass(UserModel user) async {
    if (user.enrolledClassIds.contains(widget.classModel.id)) {
      return; // Already enrolled
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Remove pending payment status if it exists for this class
      Map<String, String>? updatedPendingPayments;
      if (user.pendingClassPayments != null && 
          user.pendingClassPayments!.containsKey(widget.classModel.id)) {
        updatedPendingPayments = Map<String, String>.from(user.pendingClassPayments!);
        updatedPendingPayments.remove(widget.classModel.id);
        // If map becomes empty, set to null
        if (updatedPendingPayments.isEmpty) {
          updatedPendingPayments = null;
        }
      } else {
        updatedPendingPayments = user.pendingClassPayments;
      }

      final updatedUser = user.copyWith(
        enrolledClassIds: [...user.enrolledClassIds, widget.classModel.id],
        pendingClassPayments: updatedPendingPayments,
      );
      await context.read<UserCubit>().updateUser(updatedUser);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} telah ditambah ke kelas'),
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
            content: Text('Ralat menambah pelajar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeStudentFromClass(UserModel user) async {
    if (!user.enrolledClassIds.contains(widget.classModel.id)) {
      return; // Not enrolled
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluarkan Pelajar'),
        content: Text('Adakah anda pasti mahu mengeluarkan ${user.name} daripada kelas ini?'),
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
            child: const Text('Keluarkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedEnrolledClassIds = user.enrolledClassIds
          .where((id) => id != widget.classModel.id)
          .toList();
      
      final updatedUser = user.copyWith(
        enrolledClassIds: updatedEnrolledClassIds,
      );
      await context.read<UserCubit>().updateUser(updatedUser);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} telah dikeluarkan daripada kelas'),
            backgroundColor: Colors.orange,
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
            content: Text('Ralat mengeluarkan pelajar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classModel.title),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: BlocBuilder<UserCubit, UserState>(
        builder: (context, userState) {
          if (userState.status == UserStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (userState.status == UserStatus.error) {
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
                  Text('Ralat memuatkan pengguna'),
                  const SizedBox(height: 8),
                  Text(
                    userState.error ?? 'Ralat tidak diketahui',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<UserCubit>().fetchUsers(),
                    child: const Text('Cuba Lagi'),
                  ),
                ],
              ),
            );
          }

          final allUsers = userState.users;
          final enrolledStudents = _getEnrolledStudents(allUsers);
          final availableStudents = _getAvailableStudents(allUsers);
          final searchResults = _filterSearchResults(availableStudents);

          return Column(
            children: [
              // Class Info Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.classModel.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pengajar: ${widget.classModel.instructor}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pelajar Terdaftar: ${enrolledStudents.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari pelajar (nama, email, atau telefon)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _searchQuery.isEmpty
                        ? _buildEnrolledStudentsList(enrolledStudents)
                        : _buildSearchResultsList(searchResults),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEnrolledStudentsList(List<UserModel> enrolledStudents) {
    if (enrolledStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Tiada pelajar terdaftar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gunakan bar carian di atas untuk menambah pelajar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: enrolledStudents.length,
      itemBuilder: (context, index) {
        final student = enrolledStudents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: student.profileImage != null
                  ? NetworkImage(student.profileImage!)
                  : null,
              child: student.profileImage == null
                  ? Text(
                      student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : null,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              student.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.email),
                if (student.phone != null && student.phone!.isNotEmpty)
                  Text(
                    student.phone!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: Theme.of(context).colorScheme.error,
              onPressed: () => _removeStudentFromClass(student),
              tooltip: 'Keluarkan pelajar',
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResultsList(List<UserModel> searchResults) {
    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Tiada hasil carian',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuba cari dengan nama, email, atau nombor telefon',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Hasil Carian (${searchResults.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final student = searchResults[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: student.profileImage != null
                        ? NetworkImage(student.profileImage!)
                        : null,
                    child: student.profileImage == null
                        ? Text(
                            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : null,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    student.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.email),
                      if (student.phone != null && student.phone!.isNotEmpty)
                        Text(
                          student.phone!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () => _addStudentToClass(student),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

