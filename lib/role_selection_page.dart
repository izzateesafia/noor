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

  @override
  void initState() {
    super.initState();
    // Check if user is already logged in and redirect to dashboard
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final userCubit = UserCubit(UserRepository());
      await userCubit.fetchCurrentUser();
      
      if (mounted) {
        if (userCubit.state.status == UserStatus.loaded && userCubit.state.currentUser != null) {
          // User is already logged in, go to dashboard
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } catch (e) {
      print('Error checking auth status in role selection: $e');
    }
  }

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
    });
    // Navigate to dashboard after role selection
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
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
                _buildRoleCard(
                  icon: Icons.school,
                  label: 'Jurulatih',
                  selected: _selectedRole == 'Trainer',
                  onTap: () => _selectRole('Trainer'),
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                _buildRoleCard(
                  icon: Icons.star,
                  label: 'Master Trainer',
                  selected: _selectedRole == 'Master Trainer',
                  onTap: () => _selectRole('Master Trainer'),
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                _buildRoleCard(
                  icon: Icons.person,
                  label: 'Student',
                  selected: _selectedRole == 'Student',
                  onTap: () => _selectRole('Student'),
                  color: AppColors.primary
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedRole != null ? AppColors.primary : AppColors.disabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _selectedRole != null
                      ? () {
                          Navigator.pushReplacementNamed(context, '/dashboard');
                        }
                      : null,
                  child: const Text(
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