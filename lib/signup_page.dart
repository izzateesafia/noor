import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'repository/user_repository.dart';
import 'models/user_model.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';
import 'main.dart';
import 'utils/toast_util.dart';
import 'services/google_auth_service.dart';

class SignupPage extends StatefulWidget {
  final String? preFilledEmail;
  
  const SignupPage({super.key, this.preFilledEmail});

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

  @override
  void initState() {
    super.initState();
    // Pre-fill email if provided
    if (widget.preFilledEmail != null && widget.preFilledEmail!.isNotEmpty) {
      _emailController.text = widget.preFilledEmail!;
    }
  }

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
      // Use GoogleAuthService directly for signup
      final googleAuthService = GoogleAuthService();
      final user = await googleAuthService.signInWithGoogle();
      
      if (user != null && mounted) {
        // Successfully signed in with Google - show loading while navigating
        // Hide any existing snackbars
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).clearSnackBars();
        
        // Keep loading state while navigating
        // Check if user needs to complete biodata
        if (!user.hasCompletedBiodata) {
          Navigator.pushReplacementNamed(
            context,
            '/biodata',
            arguments: user,
          );
        } else {
          Navigator.pushReplacementNamed(context, '/role');
        }
      } else if (mounted) {
        // User cancelled or sign-in failed
        setState(() {
          _isLoading = false;
        });
        // Don't show error if user cancelled
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Log masuk Google gagal. Sila cuba lagi.';
        if (e.toString().contains('cancelled')) {
          // User cancelled, don't show error
          setState(() {
            _isLoading = false;
          });
          return;
        } else if (e.toString().contains('network') || e.toString().contains('Network')) {
          errorMessage = 'Masalah sambungan internet. Sila semak sambungan anda.';
        } else if (e.toString().contains('timeout') || e.toString().contains('Timeout') || e.toString().contains('Masa tamat')) {
          errorMessage = 'Masa tamat. Sila pastikan sambungan internet anda stabil dan cuba lagi.';
        }
        ToastUtil.showError(context, errorMessage);
        setState(() {
          _isLoading = false;
        });
      }
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

  String _getUserFriendlyError(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'Emel ini sudah digunakan. Sila gunakan emel lain atau log masuk.';
      case 'invalid-email':
        return 'Format emel tidak sah. Sila masukkan emel yang betul.';
      case 'weak-password':
        return 'Kata laluan terlalu lemah. Sila gunakan kata laluan yang lebih kuat (minimum 6 aksara).';
      case 'operation-not-allowed':
        return 'Operasi tidak dibenarkan. Sila hubungi admin.';
      case 'network-request-failed':
        return 'Masalah sambungan internet. Sila semak sambungan anda.';
      case 'too-many-requests':
        return 'Terlalu banyak percubaan. Sila cuba lagi selepas beberapa minit.';
      default:
        return 'Pendaftaran gagal. Sila cuba lagi.';
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for birth date
    final birthDateError = _validateBirthDate();
    if (birthDateError != null) {
      ToastUtil.showError(context, birthDateError);
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
        address: _addressController.text.trim().isEmpty 
            ? null 
            : {
                'line1': _addressController.text.trim(),
                'street': '',
                'postcode': '',
                'city': '',
                'state': '',
                'country': '',
              },
        roles: const [UserType.student],
        isPremium: false,
      );
      
      final cred = await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(), 
        password: _passwordController.text
      );
      await saveUserToken();
      
      // Send email verification in background (don't block user flow)
      cred.user?.sendEmailVerification().then((_) {
        print('Email verification sent');
      }).catchError((e) {
        print('Error sending email verification: $e');
      });
      
      if (mounted) {
        // Show info about email verification (non-blocking)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emel pengesahan telah dihantar. Sila periksa peti masuk anda.'),
            duration: Duration(seconds: 3),
          ),
        );
        
        // Always navigate to biodata page after signup
        Navigator.pushReplacementNamed(context, '/biodata', arguments: user);
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (mounted) {
        final errorMessage = _getUserFriendlyError(e.code);
        ToastUtil.showError(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError(context, 'Pendaftaran gagal. Sila cuba lagi.');
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
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memproses log masuk...'),
                ],
              ),
            )
          : Padding(
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