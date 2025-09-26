import 'package:daily_quran/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_constants.dart';
import 'models/class_model.dart';
import 'class_payment_page.dart';
import 'cubit/class_cubit.dart';
import 'cubit/class_states.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  // Mock user (replace with real user from provider/auth)
  UserModel user = UserModel(
    phone: '',
    id: 'u1',
    name: 'Ali',
    email: 'ali@email.com',
    userType: UserType.nonAdmin,
    isPremium: false,
    enrolledClassIds: [],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassCubit>().fetchClasses();
    });
  }

  void _enroll(ClassModel classModel) {
    if (classModel.price > 0.0) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ClassPaymentPage(classModel: classModel, user: user),
        ),
      );
      return;
    }
    setState(() {
      user = user.enrollInClass(classModel.id);
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pendaftaran Berjaya'),
        content: Text('Anda telah mendaftar dalam ${classModel.title}.'),
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
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: state.classes.length,
              itemBuilder: (context, index) {
                final classItem = state.classes[index];
                final enrolled = user.enrolledClassIds.contains(classItem.id);
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Theme.of(context).cardColor,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (classItem.image != null && classItem.image!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  classItem.image!,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.image,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 36,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(width: 18),
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
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          classItem.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              classItem.price == 0.0 ? 'Free' : 'RM ${classItem.price.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: classItem.price == 0.0
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: enrolled ? null : () => _enroll(classItem),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: enrolled
                                    ? Theme.of(context).disabledColor
                                    : Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              ),
                              child: Text(enrolled ? 'Enrolled' : 'Enroll'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No classes available', style: Theme.of(context).textTheme.bodyMedium));
          }
        },
      ),
    );
  }
} 
