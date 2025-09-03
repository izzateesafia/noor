import 'package:daily_quran/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/user_cubit.dart';
import '../cubit/class_cubit.dart';
import '../cubit/class_states.dart';
import '../repository/user_repository.dart';
import '../repository/class_repository.dart';

class UserDetailPage extends StatelessWidget {
  final UserModel user;

  const UserDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => UserCubit(UserRepository())),
        BlocProvider(create: (_) => ClassCubit(ClassRepository())),
      ],
      child: _UserDetailView(user: user),
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
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late UserType _selectedUserType;
  late bool _isPremium;
  DateTime? _selectedBirthDate;
  String? _birthDateText;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // Fetch classes to show enrolled classes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassCubit>().fetchClasses();
    });
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _selectedUserType = widget.user.userType;
    _isPremium = widget.user.isPremium;
    _selectedBirthDate = widget.user.birthDate;
    _birthDateText = widget.user.birthDate != null
        ? DateFormat('yyyy-MM-dd').format(widget.user.birthDate!)
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? now.subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateText = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveChanges() {
    final updatedUser = widget.user.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      userType: _selectedUserType,
      isPremium: _isPremium,
      birthDate: _selectedBirthDate,
    );

    context.read<UserCubit>().updateUser(updatedUser);
    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User updated successfully')),
    );
  }

  void _cancelEdit() {
    _initializeControllers();
    setState(() {
      _isEditing = false;
    });
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
        title: Text(_isEditing ? 'Edit User' : 'User Details'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _cancelEdit,
            ),
          ],
        ],
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
                    backgroundColor: widget.user.userType == UserType.admin
                        ? Colors.red.shade100
                        : Colors.blue.shade100,
                    child: Icon(
                      widget.user.userType == UserType.admin
                          ? Icons.admin_panel_settings
                          : Icons.person,
                      color: widget.user.userType == UserType.admin
                          ? Colors.red
                          : Colors.blue,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing) ...[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<UserType>(
                            value: _selectedUserType,
                            decoration: const InputDecoration(
                              labelText: 'User Type',
                              border: OutlineInputBorder(),
                            ),
                            items: UserType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type == UserType.admin ? 'Admin' : 'User'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedUserType = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SwitchListTile(
                            title: const Text('Premium'),
                            value: _isPremium,
                            onChanged: (value) => setState(() => _isPremium = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickBirthDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Birth Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_birthDateText ?? 'Select birth date'),
                      ),
                    ),
                  ] else ...[
                    _buildInfoRow('Name', widget.user.name, icon: Icons.person),
                    _buildInfoRow('Email', widget.user.email, icon: Icons.email),
                    _buildInfoRow('Phone', widget.user.phone, icon: Icons.phone),
                    if (widget.user.address != null && widget.user.address!.isNotEmpty)
                      _buildInfoRow('Address', widget.user.address!, icon: Icons.location_on),
                    if (widget.user.birthDate != null)
                      _buildInfoRow(
                        'Birth Date',
                        DateFormat('MMMM dd, yyyy').format(widget.user.birthDate!),
                        icon: Icons.cake,
                      ),
                    _buildInfoRow(
                      'User Type',
                      widget.user.userType == UserType.admin ? 'Admin' : 'User',
                      icon: Icons.admin_panel_settings,
                    ),
                    _buildInfoRow(
                      'Premium Status',
                      widget.user.isPremium ? 'Premium' : 'Free',
                      icon: Icons.star,
                    ),
                  ],
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