import 'package:daily_quran/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'main.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';
import 'repository/user_repository.dart';
import 'services/google_auth_service.dart';
import 'services/location_service.dart';
import 'repository/app_settings_repository.dart';
import 'utils/toast_util.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loginAttempted = false;
  String? _lastErrorCode;
  String? _lastEmail;
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getUserFriendlyError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Pengguna tidak dijumpai. Tiada akaun? Daftar di sini.';
      case 'wrong-password':
        return 'Kata laluan salah. Sila cuba lagi.';
      case 'invalid-email':
        return 'Format emel tidak sah. Sila masukkan emel yang betul.';
      case 'user-disabled':
        return 'Akaun anda telah dinyahaktifkan. Sila hubungi admin.';
      case 'too-many-requests':
        return 'Terlalu banyak percubaan. Sila cuba lagi selepas beberapa minit.';
      case 'network-request-failed':
        return 'Masalah sambungan internet. Sila semak sambungan anda.';
      case 'invalid-credential':
        return 'Emel atau kata laluan tidak betul. Sila cuba lagi.';
      case 'email-already-in-use':
        return 'Emel ini sudah digunakan.';
      case 'weak-password':
        return 'Kata laluan terlalu lemah. Sila gunakan kata laluan yang lebih kuat.';
      case 'operation-not-allowed':
        return 'Operasi tidak dibenarkan. Sila hubungi admin.';
      default:
        return 'Log masuk gagal. Sila cuba lagi.';
    }
  }

  Future<void> _handleLogin(
    BuildContext context,
    String email,
    String password,
  ) async {
    setState(() {
      _loginAttempted = true;
    });
    if (email.trim().isEmpty) {
      ToastUtil.showError(context, 'Sila masukkan emel atau telefon.');
      return;
    }
    if (password.trim().isEmpty) {
      ToastUtil.showError(context, 'Sila masukkan kata laluan.');
      return;
    }

    try {
      await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await saveUserToken();

      // Fetch user from Firestore to verify they exist
      final userRepo = UserRepository();
      final user = await userRepo.getCurrentUser();

      if (user == null) {
        // User authenticated but doesn't exist in Firestore
        await firebase_auth.FirebaseAuth.instance.signOut();
        setState(() {
          _lastErrorCode = 'user-not-found';
          _lastEmail = email.trim();
        });
        ToastUtil.showError(
          context,
          'Akaun tidak dijumpai dalam sistem. Sila daftar terlebih dahulu.',
        );
        return;
      }

      // Show success message
      if (mounted) {
        ToastUtil.showSuccess(
          context,
          'Log masuk berjaya! Selamat datang kembali.',
        );
      }

      // Request location permission and get location
      if (mounted && user.hasCompletedBiodata) {
        await _requestLocationAndUpdateUser(context, user);
      }

      // User exists, navigate directly to dashboard or biodata
      if (mounted) {
        if (user.hasCompletedBiodata) {
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          Navigator.pushReplacementNamed(context, '/biodata', arguments: user);
        }
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      setState(() {
        _lastErrorCode = e.code;
        _lastEmail = email.trim();
      });
      final errorMessage = _getUserFriendlyError(e.code);
      ToastUtil.showError(context, errorMessage);
    } catch (e) {
      setState(() {
        _lastErrorCode = null;
        _lastEmail = null;
      });
      ToastUtil.showError(context, 'Log masuk gagal. Sila cuba lagi.');
    }
  }

  Future<bool> _checkAndRequestLocationPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      bool shouldRequest = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Kebenaran Lokasi'),
          content: const Text(
            'Aplikasi ini memerlukan akses ke lokasi anda untuk memberikan arah Qiblah dan ciri-ciri lain.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Tolak'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Benarkan'),
            ),
          ],
        ),
      );
      if (shouldRequest != true) return false;
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Kebenaran Diperlukan'),
          content: const Text(
            'Kebenaran lokasi telah ditolak secara kekal. Sila aktifkan dalam tetapan peranti anda.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _requestLocationAndUpdateUser(BuildContext context, user) async {
    try {
      final locationService = LocationService();

      // Request location permission
      final hasPermission = await _checkAndRequestLocationPermission(context);
      if (!hasPermission) return;

      // Get current location
      final position = await locationService.getCurrentLocation();
      if (position == null) return;

      // Get location name
      final locationName = await locationService.getLocationName(
        position.latitude,
        position.longitude,
      );

      // Update user with location
      final userCubit = context.read<UserCubit>();
      final updatedUser = user.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        locationName:
            locationName ??
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
      );

      await userCubit.updateUser(updatedUser);
    } catch (e) {
      // Don't block login if location fails
    }
  }

  Future<void> _showPasswordResetDialog(BuildContext context) async {
    final emailController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Semula Kata Laluan'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Masukkan emel anda'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(emailController.text.trim()),
            child: const Text('Hantar'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
          email: result,
        );
        ToastUtil.showSuccess(
          context,
          'Emel set semula kata laluan telah dihantar!',
        );
      } on firebase_auth.FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage =
                'Emel tidak dijumpai. Sila pastikan emel anda betul.';
            break;
          case 'invalid-email':
            errorMessage = 'Format emel tidak sah.';
            break;
          case 'network-request-failed':
            errorMessage = 'Masalah sambungan internet.';
            break;
          default:
            errorMessage = 'Gagal menghantar emel set semula. Sila cuba lagi.';
        }
        ToastUtil.showError(context, errorMessage);
      } catch (e) {
        ToastUtil.showError(
          context,
          'Gagal menghantar emel set semula. Sila cuba lagi.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = UserCubit(UserRepository());
        
        // Only fetch current user if already authenticated
        // This prevents showing error for "No user data found" before login
        final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          cubit.fetchCurrentUser();
        }

        // Auto-reset if stuck in loading state for too long
        Future.delayed(const Duration(seconds: 10), () {
          if (cubit.state.status == UserStatus.loading) {
            cubit.resetState();
          }
        });

        return cubit;
      },
      child: BlocConsumer<UserCubit, UserState>(
        listener: (context, state) async {
          if (state.status == UserStatus.loaded && state.currentUser != null) {
            final user = state.currentUser!;

            // Show success message for Google Sign-In
            ToastUtil.showSuccess(
              context,
              'Log masuk berjaya! Selamat datang kembali.',
            );

            // Request location permission and get location (only if biodata completed)
            if (user.hasCompletedBiodata) {
              await _requestLocationAndUpdateUser(context, user);
            }

            // Navigate directly to dashboard or biodata
            // Use pushReplacementNamed to remove login page from stack
            // This prevents the listener from firing after navigation
            if (mounted) {
              if (user.hasCompletedBiodata) {
                Navigator.pushReplacementNamed(context, '/main');
              } else {
                Navigator.pushReplacementNamed(context, '/biodata', arguments: user);
              }
            }
          } else if (_loginAttempted &&
              state.status == UserStatus.error &&
              state.error != null &&
              mounted) {
            // Only show errors if we're still on the login page
            // Check if current route is still login to prevent showing errors after navigation
            final currentRoute = ModalRoute.of(context);
            if (currentRoute?.settings.name != '/login' && 
                currentRoute?.settings.name != null) {
              // We've navigated away, don't show error
              return;
            }
            
            // Show toast for sign-in errors only if an attempt was made
            String errorMessage = state.error!;
            
            // Skip showing error for expected pre-login errors
            if (errorMessage.contains('No user data found') ||
                errorMessage.contains('Please try logging in again')) {
              // This is expected before login completes, don't show error
              return;
            }
            
            if (errorMessage.contains('cancelled')) {
              // User cancelled, don't show error
              return;
            } else if (errorMessage.contains('network') ||
                errorMessage.contains('Network')) {
              errorMessage =
                  'Masalah sambungan internet. Sila semak sambungan anda.';
            } else if (errorMessage.contains('timeout') ||
                errorMessage.contains('Timeout') ||
                errorMessage.contains('Masa tamat')) {
              errorMessage =
                  'Masa tamat. Sila pastikan sambungan internet anda stabil dan cuba lagi.';
            } else if (errorMessage.contains('sign_in_failed')) {
              errorMessage = 'Log masuk Google gagal. Sila cuba lagi.';
            } else if (errorMessage.contains('Apple') || errorMessage.contains('apple')) {
              // Show more specific Apple Sign-In errors
              if (errorMessage.contains('identity token') || errorMessage.contains('credential')) {
                errorMessage = 'Ralat pengesahan Apple. Sila cuba lagi atau gunakan kaedah log masuk lain.';
              } else if (errorMessage.contains('Failed to sign in with Apple:')) {
                final actualError = errorMessage.split('Failed to sign in with Apple:').last.trim();
                if (actualError.contains('INVALID_IDP_RESPONSE') || actualError.contains('invalid')) {
                  errorMessage = 'Ralat konfigurasi Apple Sign-In. Sila hubungi sokongan.';
                } else {
                  errorMessage = 'Log masuk Apple gagal: $actualError';
                }
              } else {
                errorMessage = 'Log masuk Apple gagal. Sila cuba lagi.';
              }
            } else {
              errorMessage = 'Log masuk gagal. Sila cuba lagi.';
            }
            ToastUtil.showError(context, errorMessage);
          }
        },
        builder: (context, state) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            resizeToAvoidBottomInset: true,
            body: state.status == UserStatus.loading
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Theme.of(context).scaffoldBackgroundColor,
                                Theme.of(context).scaffoldBackgroundColor,
                              ]
                            : [
                                Colors.white,
                                Colors.grey.shade50,
                              ],
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Theme.of(context).scaffoldBackgroundColor,
                                Theme.of(context).scaffoldBackgroundColor,
                              ]
                            : [
                                Colors.white,
                                Colors.grey.shade50,
                              ],
                      ),
                    ),
                    child: SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                MediaQuery.of(context).size.height -
                                MediaQuery.of(context).padding.top -
                                MediaQuery.of(context).padding.bottom,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 32),
                                Text(
                                  'Daily Quran',
                                  style: TextStyle(
                                    letterSpacing: 2.0,
                                    fontFamily: 'Kahfi',
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: AppColors.primary.withOpacity(0.2),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Selamat datang kembali',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 48),
                                // Email Field with icon
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _emailController,
                                    enabled: true,
                                    decoration: InputDecoration(
                                      labelText: 'Emel atau Telefon',
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? Theme.of(context).cardColor
                                          : Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (value) {
                                      if (_lastErrorCode != null) {
                                        setState(() {
                                          _lastErrorCode = null;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Password Field with icon
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _passwordController,
                                    enabled: true,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Kata Laluan',
                                      prefixIcon: Icon(
                                        Icons.lock_outlined,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? Theme.of(context).cardColor
                                          : Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => _showPasswordResetDialog(context),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    child: Text(
                                      'Lupa Kata Laluan?',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Login Button
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primary.withOpacity(0.8),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.4),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: (state.status == UserStatus.loading)
                                        ? null
                                        : () => _handleLogin(
                                            context,
                                            _emailController.text.trim(),
                                            _passwordController.text.trim(),
                                          ),
                                    child: state.status == UserStatus.loading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Log Masuk',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Divider with "atau"
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'atau',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Google Sign-In Button
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    color: isDark
                                        ? Theme.of(context).cardColor
                                        : Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: (state.status == UserStatus.loading)
                                        ? null
                                        : () {
                                            setState(() {
                                              _loginAttempted = true;
                                            });
                                            context.read<UserCubit>().signInWithGoogle();
                                          },
                                    icon: Image.asset(
                                      'assets/images/google_logo.png',
                                      width: 24,
                                      height: 24,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.g_mobiledata,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 24,
                                        );
                                      },
                                    ),
                                    label: Text(
                                      'Log masuk dengan Google',
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Apple Sign-In Button
                                FutureBuilder<bool>(
                                  future: SignInWithApple.isAvailable(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState != ConnectionState.done) {
                                      return const SizedBox.shrink();
                                    }
                                    if (snapshot.data != true) {
                                      return const SizedBox.shrink();
                                    }
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: SignInWithAppleButton(
                                        onPressed: () {
                                          if (state.status == UserStatus.loading) return;
                                          setState(() {
                                            _loginAttempted = true;
                                          });
                                          context.read<UserCubit>().signInWithApple();
                                        },
                                        style: SignInWithAppleButtonStyle.black,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 32),
                                // Sign Up Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Tiada akaun? ',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        fontSize: 15,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/signup',
                                          arguments: _emailController.text.trim().isNotEmpty
                                              ? _emailController.text.trim()
                                              : null,
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: Text(
                                        'Daftar',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Show prominent signup button if user-not-found error occurred
                                if (_lastErrorCode == 'user-not-found') ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide.none,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/signup',
                                          arguments: _lastEmail ?? _emailController.text.trim(),
                                        );
                                      },
                                      icon: const Icon(Icons.person_add, size: 22),
                                      label: const Text(
                                        'Daftar Akaun Baru',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                // Debug buttons
                                if (state.status == UserStatus.loading)
                                  TextButton(
                                    onPressed: () {
                                      context.read<UserCubit>().resetState();
                                    },
                                    child: const Text('Reset (Debug)'),
                                  ),
                                const SizedBox(height: 40), // Bottom padding for keyboard
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ));
        },
      ),
    );
  }
}
