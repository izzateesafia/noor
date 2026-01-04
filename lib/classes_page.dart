import 'package:daily_quran/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_constants.dart';
import 'models/class_model.dart';
import 'class_payment_page.dart';
import 'pages/class_detail_page.dart';
import 'cubit/class_cubit.dart';
import 'cubit/class_states.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassCubit>().fetchClasses();
    });
  }

  void _enroll(ClassModel classModel, UserModel user) async {
    if (classModel.price > 0.0) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ClassPaymentPage(classModel: classModel, user: user),
        ),
      );
      // Refresh user data after returning from payment page
      if (mounted) {
        await context.read<UserCubit>().fetchCurrentUser();
        // Also refresh classes to ensure UI updates
        context.read<ClassCubit>().fetchClasses();
      }
      return;
    }
    setState(() {
      user = user.enrollInClass(classModel.id);
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pendaftaran Berjaya'),
        content: Text('Anda telah mendaftar Kelas ${classModel.title}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
        builder: (context, userState) {
          // Ensure user data is loaded if needed
          if (userState.status == UserStatus.initial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<UserCubit>().fetchCurrentUser();
            });
          }
          
          final user = userState.currentUser;
          if (user == null) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return Scaffold(
      appBar: AppBar(
        title: const Text('Kelas'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<ClassCubit, ClassState>(
        builder: (context, state) {
          if (state.status == ClassStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == ClassStatus.error) {
            return Center(child: Text('Gagal memuatkan kelas', style: TextStyle(color: Theme.of(context).colorScheme.error)));
          } else if (state.status == ClassStatus.loaded && state.classes.isNotEmpty) {
            final visibleClasses = state.classes.where((c) => !c.isHidden).toList();
            if (visibleClasses.isEmpty) {
              return Center(
                child: Text(
                  'Tiada kelas tersedia',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                // Refresh both user data and classes
                await context.read<UserCubit>().fetchCurrentUser();
                await context.read<ClassCubit>().fetchClasses();
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                itemCount: visibleClasses.length,
                itemBuilder: (context, index) {
                final classItem = visibleClasses[index];
                final enrolled = user.enrolledClassIds.contains(classItem.id);
                final isPaymentPending = user.isPaymentPendingForClass(classItem.id);
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Theme.of(context).cardColor,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () {
                      if (enrolled) {
                        // Navigate to class detail page if enrolled
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ClassDetailPage(
                              classModel: classItem,
                              user: user,
                            ),
                          ),
                        );
                      } else {
                        // Navigate to payment page if not enrolled
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ClassPaymentPage(
                              classModel: classItem,
                              user: user,
                            ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge at top if enrolled or pending
                        if (enrolled)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              // color: Theme.of(context).colorScheme.primaryContainer,
                              color: Colors.green,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Berdaftar',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isPaymentPending)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.hourglass_empty,
                                  size: 18,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Menunggu pengesahan',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        // Image on the left
                        if (classItem.image != null && classItem.image!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: classItem.image!.startsWith('http://') || classItem.image!.startsWith('https://')
                                ? Image.network(
                                    classItem.image!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.image,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 48,
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceVariant,
                                          borderRadius: BorderRadius.circular(10),
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
                                    classItem.image!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.image,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 48,
                                        ),
                                      );
                                    },
                                  ),
                          )
                        else
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.class_,
                              color: Theme.of(context).colorScheme.primary,
                              size: 48,
                            ),
                          ),
                        const SizedBox(width: 16),
                        // Details on the right
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                classItem.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                classItem.instructor,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                classItem.description,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    classItem.price == 0.0 ? 'Percuma' : 'RM ${classItem.price.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: classItem.price == 0.0
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).textTheme.bodyLarge?.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (!enrolled && !isPaymentPending) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _enroll(classItem, user),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                        child: const Text('Daftar'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              ),
            );
          } else {
            return Center(child: Text('No classes available', style: Theme.of(context).textTheme.bodyMedium));
          }
        },
      ),
    );
        },
      );
  }
} 
