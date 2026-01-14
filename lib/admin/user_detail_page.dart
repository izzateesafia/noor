import 'package:daily_quran/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_states.dart';
import '../cubit/class_cubit.dart';
import '../cubit/class_states.dart';
import '../repository/user_repository.dart';
import '../repository/class_repository.dart';

class UserDetailPage extends StatelessWidget {
  final UserModel user;

  const UserDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Get the existing UserCubit for admin check (should be available from app context)
    final existingUserCubit = context.read<UserCubit>();
    
    return MultiBlocProvider(
      providers: [
        // Create a new UserCubit for editing the user
        BlocProvider(create: (_) => UserCubit(UserRepository())),
        BlocProvider(create: (_) => ClassCubit(ClassRepository())),
      ],
      child: BlocBuilder<UserCubit, UserState>(
        bloc: existingUserCubit,
        builder: (context, state) {
          // Check if current user is admin using the existing UserCubit
          final currentUser = state.currentUser;
          final isAdmin = currentUser?.roles.contains(UserType.admin) ?? false;
          
          if (!isAdmin) {
            // Non-admin users should not access this page
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Akses ditolak: Hanya admin boleh mengakses halaman ini.'),
                  backgroundColor: Colors.red,
                ),
              );
            });
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Admin check passed, show the user detail view
          return _UserDetailView(user: user);
        },
      ),
    );
  }
}

class _UserDetailView extends StatefulWidget {
  final UserModel user;

  const _UserDetailView({required this.user});

  @override
  State<_UserDetailView> createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<_UserDetailView> {
  @override
  void initState() {
    super.initState();
    // Fetch classes to show enrolled classes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassCubit>().fetchClasses();
    });
  }

  /// Format address map as a readable string for display
  String _formatAddressForDisplay(Map<String, String>? address) {
    if (address == null) return '';
    final parts = <String>[];
    if (address['line1']?.isNotEmpty ?? false) parts.add(address['line1']!);
    if (address['street']?.isNotEmpty ?? false) parts.add(address['street']!);
    if (address['postcode']?.isNotEmpty ?? false) parts.add(address['postcode']!);
    if (address['city']?.isNotEmpty ?? false) parts.add(address['city']!);
    if (address['state']?.isNotEmpty ?? false) parts.add(address['state']!);
    if (address['country']?.isNotEmpty ?? false) parts.add(address['country']!);
    return parts.join(', ');
  }

  /// Get role badges for display
  List<Widget> _getRoleBadges() {
    final badges = <Widget>[];
    
    if (widget.user.roles.contains(UserType.admin)) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Text(
            'Admin',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    if (widget.user.roles.contains(UserType.masterTrainer)) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade300),
          ),
          child: Text(
            'Master Trainer',
            style: TextStyle(
              color: Colors.purple.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    if (widget.user.roles.contains(UserType.trainer)) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade300),
          ),
          child: Text(
            'Jurulatih',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    if (widget.user.roles.contains(UserType.student)) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            'Pelajar',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    return badges;
  }

  Widget _buildInfoCard({
    required String title,
    required Widget child,
    Color? color,
  }) {
    return Card(
      elevation: 2,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        // No edit button - this page is read-only
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Avatar and Basic Info
            _buildInfoCard(
              title: 'Basic Information',
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: widget.user.roles.contains(UserType.admin)
                        ? Colors.red.shade100
                        : Colors.blue.shade100,
                    child: Icon(
                      widget.user.roles.contains(UserType.admin)
                          ? Icons.admin_panel_settings
                          : Icons.person,
                      color: widget.user.roles.contains(UserType.admin)
                          ? Colors.red
                          : Colors.blue,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // All fields are read-only - no editing allowed
                    _buildInfoRow('Name', widget.user.name, icon: Icons.person),
                    _buildInfoRow('Email', widget.user.email, icon: Icons.email),
                    _buildInfoRow('Phone', widget.user.phone ?? 'N/A', icon: Icons.phone),
                    if (widget.user.address != null)
                      _buildInfoRow('Address', _formatAddressForDisplay(widget.user.address), icon: Icons.location_on),
                    if (widget.user.birthDate != null)
                      _buildInfoRow(
                        'Birth Date',
                        DateFormat('MMMM dd, yyyy').format(widget.user.birthDate!),
                        icon: Icons.cake,
                      ),
                  const SizedBox(height: 8),
                  // Display roles as badges
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Roles:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _getRoleBadges(),
                    ),
                    ],
                  ),
                  const SizedBox(height: 8),
                    _buildInfoRow(
                      'Premium Status',
                      widget.user.isPremium ? 'Premium' : 'Free',
                      icon: Icons.star,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Premium Information
            if (widget.user.isPremium)
              _buildInfoCard(
                title: 'Premium Information',
                color: Colors.amber.shade50,
                child: Column(
                  children: [
                    if (widget.user.premiumStartDate != null)
                      _buildInfoRow(
                        'Premium Start Date',
                        DateFormat('MMMM dd, yyyy').format(widget.user.premiumStartDate!),
                        icon: Icons.calendar_today,
                      ),
                    if (widget.user.premiumEndDate != null)
                      _buildInfoRow(
                        'Premium End Date',
                        DateFormat('MMMM dd, yyyy').format(widget.user.premiumEndDate!),
                        icon: Icons.calendar_today,
                      ),
                  ],
                ),
              ),

            if (widget.user.isPremium) const SizedBox(height: 16),

            // Enrolled Classes
            _buildInfoCard(
              title: 'Enrolled Classes (${widget.user.enrolledClassIds.length})',
              child: BlocBuilder<ClassCubit, ClassState>(
                builder: (context, classState) {
                  if (classState.status == ClassStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (classState.status == ClassStatus.error) {
                    return Text('Error loading classes: ${classState.error}');
                  }

                  final enrolledClasses = classState.classes
                      .where((classModel) => widget.user.enrolledClassIds.contains(classModel.id))
                      .toList();

                  if (enrolledClasses.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No classes enrolled',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: enrolledClasses.map((classModel) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(Icons.class_, color: Colors.blue),
                          ),
                          title: Text(
                            classModel.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${classModel.instructor} • ${classModel.time}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: Text(
                            classModel.price == 0 ? 'Free' : '\$${classModel.price}',
                            style: TextStyle(
                              color: classModel.price == 0 ? Colors.green : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 