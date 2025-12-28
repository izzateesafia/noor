import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_constants.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';
import 'repository/user_repository.dart';
import 'models/user_model.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String? _selectedRole;
  bool _isSaving = false;
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    setState(() {
      _isLoadingUser = true;
    });

    try {
      // Fetch current user from Firebase
      context.read<UserCubit>().fetchCurrentUser();
    } catch (e) {
      print('Error fetching user info: $e');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
    });
  }

  Future<void> _saveRole() async {
    if (_selectedRole == null) return;
    
    // Refresh user info before checking
    await _fetchUserInfo();
    
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuatkan maklumat pengguna. Sila cuba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Map selection to UserType
    UserType targetType = UserType.student;
    if (_selectedRole == 'Trainer' || _selectedRole == 'Jurulatih') {
      targetType = UserType.trainer;
    } else if (_selectedRole == 'Master Trainer') {
      targetType = UserType.masterTrainer;
    } else {
      targetType = UserType.student;
    }

    // Check if selected role matches user's roles
    final userRoles = _currentUser!.roles;
    
    // Admin can access all roles - skip validation
    bool isAdmin = userRoles.contains(UserType.admin);
    
    bool roleMatches = false;
    
    if (isAdmin) {
      // Admin can select any role
      roleMatches = true;
    } else {
      // Check if role is in the roles array
      roleMatches = userRoles.contains(targetType);
    }

    if (!roleMatches) {
      // Role doesn't match - show snackbar
      String roleName = _selectedRole!;
      String userRoleName = _getRoleName(_currentUser!.userType);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Peranan yang dipilih ($roleName) tidak sepadan dengan peranan anda ($userRoleName). Sila pilih peranan yang betul.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    // Role matches - proceed to save and navigate
    setState(() {
      _isSaving = true;
    });

    // Hide any existing snackbars before navigation
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).clearSnackBars();

    // For admins, add the selected role to their roles array (set as primary)
    if (isAdmin) {
      final current = _currentUser!;
      // Ensure admin role is preserved and set targetType as primary
      final updatedRoles = [
        targetType, // Set selected role as primary
        ...current.roles.where((r) => r != targetType && r != UserType.admin),
        UserType.admin, // Keep admin role but not as primary
      ];
      final updated = current.copyWith(roles: updatedRoles);
      await context.read<UserCubit>().updateUser(updated);
    } else {
      // For non-admins, update roles (set targetType as primary)
      await context.read<UserCubit>().updateUserType(targetType);
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    Navigator.pushReplacementNamed(context, '/main');
  }

  String _getRoleName(UserType role) {
    switch (role) {
      case UserType.student:
        return 'Pelajar';
      case UserType.trainer:
        return 'Jurulatih';
      case UserType.masterTrainer:
        return 'Master Trainer';
      case UserType.admin:
        return 'Admin';
    }
  }

  List<Widget> _buildAvailableRoleCards() {
    if (_currentUser == null) return [];
    
    final userRoles = _currentUser!.roles;
    final roleCards = <Widget>[];
    
    // Always show Student role if user has it (most users will only have this)
    if (userRoles.contains(UserType.student)) {
      roleCards.add(
        _buildRoleCard(
          icon: Icons.person,
          label: 'Pelajar',
          selected: _selectedRole == 'Student',
          onTap: () => _selectRole('Student'),
          color: AppColors.primary,
        ),
      );
    }
    
    // Show Trainer role only if user has it
    if (userRoles.contains(UserType.trainer)) {
      if (roleCards.isNotEmpty) {
        roleCards.add(const SizedBox(height: 24));
      }
      roleCards.add(
        _buildRoleCard(
          icon: Icons.school,
          label: 'Jurulatih',
          selected: _selectedRole == 'Trainer',
          onTap: () => _selectRole('Trainer'),
          color: AppColors.primary,
        ),
      );
    }
    
    // Show Master Trainer role only if user has it
    if (userRoles.contains(UserType.masterTrainer)) {
      if (roleCards.isNotEmpty) {
        roleCards.add(const SizedBox(height: 24));
      }
      roleCards.add(
        _buildRoleCard(
          icon: Icons.star,
          label: 'Master Trainer',
          selected: _selectedRole == 'Master Trainer',
          onTap: () => _selectRole('Master Trainer'),
          color: AppColors.primary,
        ),
      );
    }
    
    return roleCards;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.loaded && state.currentUser != null) {
          setState(() {
            _currentUser = state.currentUser;
            _isLoadingUser = false;
          });
        } else if (state.status == UserStatus.error) {
          setState(() {
            _isLoadingUser = false;
          });
        }
      },
      child: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          if (_isLoadingUser || state.status == UserStatus.loading) {
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Memuatkan maklumat pengguna...',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pilih Peranan Anda',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontFamily: 'Kahfi',
                    color: AppColors.primary,
                    fontSize: 36,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Only show role cards for roles the user already has
                ..._buildAvailableRoleCards(),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedRole != null ? AppColors.primary : AppColors.disabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _selectedRole != null && !_isSaving
                      ? _saveRole
                      : null,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
        },
      ),
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        child: SizedBox(
          height: 120,
          child: Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
                child: Container(
                  width: 80,
                  height: 120,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.13),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                  child: Icon(icon, size: 48, color: color),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark ? AppColors.darkText : AppColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'Montserrat',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
} 