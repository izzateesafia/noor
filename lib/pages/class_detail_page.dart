import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_states.dart';

class ClassDetailPage extends StatelessWidget {
  final ClassModel classModel;
  final UserModel user;

  const ClassDetailPage({
    super.key,
    required this.classModel,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, userState) {
        final currentUser = userState.currentUser ?? user;
        final isEnrolled = currentUser.enrolledClassIds.contains(classModel.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(classModel.title),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Image at Top
                if (classModel.image != null && classModel.image!.isNotEmpty)
                  _buildClassImage(context),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enrollment Status Badge
                      if (isEnrolled) _buildEnrollmentBadge(context),

                      const SizedBox(height: 16),

                      // Class Information Card
                      _buildClassInfoCard(context),

                      const SizedBox(height: 24),

                      // Class Details
                      _buildClassDetails(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassImage(BuildContext context) {
    return ClipRRect(
      child: Image.network(
        classModel.image!,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 250,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.image_not_supported,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: double.infinity,
            height: 250,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnrollmentBadge(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anda telah mendaftar kelas ini',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Anda kini boleh mengakses semua kandungan kelas ini',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassInfoCard(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              classModel.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pengajar: ${classModel.instructor}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 16,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              classModel.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Butiran Kelas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildDetailItem(
          context,
          Icons.access_time,
          'Masa',
          classModel.time,
        ),
        const SizedBox(height: 12),
        _buildDetailItem(
          context,
          Icons.timer,
          'Tempoh',
          classModel.duration,
        ),
        const SizedBox(height: 12),
        _buildDetailItem(
          context,
          Icons.trending_up,
          'Tahap',
          classModel.level,
        ),
        const SizedBox(height: 12),
        _buildDetailItem(
          context,
          Icons.attach_money,
          'Harga',
          classModel.price == 0.0
              ? 'Percuma'
              : 'RM ${classModel.price.toStringAsFixed(2)}',
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

