import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'repository/user_repository.dart';
import 'models/user_model.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';
import 'main.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _selectedBirthDate;
  String? _birthDateText;
  bool _isLoading = false;

  // Validation patterns
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final RegExp _phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateText = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama penuh diperlukan';
    }
    if (value.trim().length < 2) {
      return 'Nama mestilah sekurang-kurangnya 2 aksara';
    }
    if (value.trim().length > 50) {
      return 'Nama mestilah kurang daripada 50 aksara';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nombor telefon diperlukan';
    }
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Sila masukkan nombor telefon yang sah';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Emel diperlukan';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Sila masukkan alamat emel yang sah';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata laluan diperlukan';
    }
    if (value.length < 6) {
      return 'Kata laluan mestilah sekurang-kurangnya 6 aksara';
    }
    if (value.length > 50) {
      return 'Kata laluan mestilah kurang daripada 50 aksara';
    }
    return null;
  }

  String? _validateBirthDate() {
    if (_selectedBirthDate != null) {
      final now = DateTime.now();
      final age = now.year - _selectedBirthDate!.year;
      if (age < 5 || age > 120) {
        return 'Sila masukkan tarikh lahir yang sah';
      }
    }
    return null;
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a temporary UserCubit for Google Sign-In
      final userCubit = UserCubit(UserRepository());
      await userCubit.signInWithGoogle();
      
      if (userCubit.state.status == UserStatus.loaded && userCubit.state.currentUser != null) {
        // Successfully signed in with Google
        Navigator.pushReplacementNamed(context, '/role');
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userCubit.state.error ?? 'Log masuk Google gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ralat log masuk Google: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _validateAddress(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length < 10) {
        return 'Alamat mestilah sekurang-kurangnya 10 aksara';
      }
      if (value.trim().length > 200) {
        return 'Alamat mestilah kurang daripada 200 aksara';
      }
    }
    return null;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for birth date
    final birthDateError = _validateBirthDate();
    if (birthDateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(birthDateError)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userRepo = UserRepository();
      final user = await userRepo.signupUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        birthDate: _selectedBirthDate,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        userType: UserType.nonAdmin,
        isPremium: false,
      );
      
      final cred = await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(), 
        password: _passwordController.text
      );
      await saveUserToken();
      await cred.user?.sendEmailVerification();
      
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Sahkan Emel Anda'),
            content: const Text('Emel pengesahan telah dihantar. Sila periksa peti masuk anda dan sahkan emel anda sebelum meneruskan.'),
            actions: [
              TextButton(
                onPressed: () async {
                  await cred.user?.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emel pengesahan dihantar semula.')));
                },
                child: const Text('Hantar Semula Emel'),
              ),
              TextButton(
                onPressed: () async {
                  await cred.user?.reload();
                  final refreshedUser = firebase_auth.FirebaseAuth.instance.currentUser;
                  if (refreshedUser != null && refreshedUser.emailVerified) {
                    Navigator.of(ctx).pop();
                    // After email verification, check if user needs to complete biodata
                    final userRepo = UserRepository();
                    final user = await userRepo.getCurrentUser();
                    if (user != null && !user.hasCompletedBiodata) {
                      Navigator.pushReplacementNamed(context, '/biodata', arguments: user);
                    } else {
                      Navigator.pushReplacementNamed(context, '/role');
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emel belum disahkan lagi.')));
                  }
                },
                child: const Text('Saya telah sahkan'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pendaftaran gagal: ${e.toString()}')),
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Buat Akaun',
                  style: TextStyle(
                    letterSpacing: 2.0,
                    fontFamily: 'Kahfi',
                    color: Colors.red.shade900,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Penuh *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: _validateName,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nombor Telefon *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Emel *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Kata Laluan *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    helperText: 'Minimum 6 aksara',
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickBirthDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Tarikh Lahir (pilihan)',
                        border: const OutlineInputBorder(),
                        hintText: 'YYYY-MM-DD',
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: _selectedBirthDate != null 
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _selectedBirthDate = null;
                                  _birthDateText = null;
                                });
                              },
                            )
                          : null,
                      ),
                      controller: TextEditingController(text: _birthDateText),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Alamat (pilihan)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.location_on),
                    helperText: 'Jalan, Bandar, Negeri, Negara',
                  ),
                  validator: _validateAddress,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isLoading ? null : _handleSignup,
                    child: _isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Daftar'),
                  ),
                ),
                const SizedBox(height: 16),
                // Divider with "OR"
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                  ],
                ),
                const SizedBox(height: 16),
                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isLoading ? null : () => _handleGoogleSignIn(),
                    icon: Icon(
                      Icons.g_mobiledata,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                    label: Text(
                                              'Daftar dengan Google',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Sudah ada akaun? Log Masuk'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 