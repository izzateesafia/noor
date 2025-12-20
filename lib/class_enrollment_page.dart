import 'package:flutter/material.dart';
import 'models/class_model.dart';
import 'models/user_model.dart';
import 'theme_constants.dart';

class ClassEnrollmentPage extends StatefulWidget {
  const ClassEnrollmentPage({super.key});

  @override
  State<ClassEnrollmentPage> createState() => _ClassEnrollmentPageState();
}

class _ClassEnrollmentPageState extends State<ClassEnrollmentPage> {
  // Mock user (replace with real user from provider/auth)
  UserModel user = UserModel(
    phone: '',
    id: 'u1',
    name: 'Ali',
    email: 'ali@email.com',
    roles: const [UserType.student],
    isPremium: false,
    enrolledClassIds: [],
  );

  // Mock classes (replace with real data from backend)
  final List<ClassModel> classes = [
    ClassModel(
      id: 'c1',
      title: 'Asas Bacaan Al-Quran',
      instructor: 'Ustaz Ahmed',
      time: 'Isnin & Rabu',
      duration: '1 jam',
      level: 'Pemula',
      description: 'Learn the fundamentals of proper Quran recitation with tajweed rules.',
      image: 'assets/images/quran_class.png',
      price: 0.0,
    ),
    ClassModel(
      id: 'c2',
      title: 'Islamic History',
      instructor: 'Dr. Fatima',
      time: 'Tuesday',
      duration: '1.5 hours',
      level: 'Intermediate',
      description: 'Explore the rich history of Islamic civilization and its contributions.',
      image: 'assets/images/history_class.png',
      price: 19.90,
    ),
    ClassModel(
      id: 'c3',
      title: 'Arabic Language',
      instructor: 'Ustadha Mariam',
      time: 'Thursday',
      duration: '1 jam',
      level: 'All Levels',
      description: 'Master the Arabic language with focus on Quranic vocabulary.',
      image: 'assets/images/arabic_class.png',
      price: 9.90,
    ),
  ];

  void _enroll(ClassModel classModel) {
    setState(() {
      user = user.enrollInClass(classModel.id);
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enrollment Successful'),
        content: Text('You have enrolled in ${classModel.title}.'),
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
        title: const Text('Enroll in Classes'),
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.onAppBar,
      ),
      backgroundColor: AppColors.background,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final classModel = classes[index];
          final enrolled = user.enrolledClassIds.contains(classModel.id);
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.only(bottom: 18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (classModel.image != null && classModel.image!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            classModel.image!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.image,
                                  color: AppColors.primary,
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
                              classModel.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Instructor: ${classModel.instructor}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 16, color: AppColors.disabled),
                                const SizedBox(width: 4),
                                Text(
                                  classModel.time,
                                  style: TextStyle(
                                    color: AppColors.disabled,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.timer, size: 16, color: AppColors.disabled),
                                const SizedBox(width: 4),
                                Text(
                                  classModel.duration,
                                  style: TextStyle(
                                    color: AppColors.disabled,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              classModel.level,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
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
                    classModel.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        classModel.price == 0.0 ? 'Free' : 'RM ${classModel.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: classModel.price == 0.0 ? AppColors.primary : AppColors.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: enrolled
                            ? null
                            : () => _enroll(classModel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: enrolled ? AppColors.disabled : AppColors.primary,
                          foregroundColor: Colors.white,
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
      ),
    );
  }
} 