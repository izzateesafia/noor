import 'package:daily_quran/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
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

      // User exists, navigate to welcome screen first
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/welcome',
          arguments: {
            'userId': user.id,
            'hasCompletedBiodata': user.hasCompletedBiodata,
          },
        );
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
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return BlocProvider(
      create: (context) {
        final cubit = UserCubit(UserRepository())..fetchCurrentUser();

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

            // // Show welcome message dialog
            // await _showWelcomeMessage(context);

            // Navigate to welcome screen first
            Navigator.pushReplacementNamed(
              context,
              '/welcome',
              arguments: {
                'userId': user.id,
                'hasCompletedBiodata': user.hasCompletedBiodata,
              },
            );
          } else if (_loginAttempted &&
              state.status == UserStatus.error &&
              state.error != null) {
            // Show toast for sign-in errors only if an attempt was made
            String errorMessage = state.error!;
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
            } else {
              errorMessage = 'Log masuk gagal. Sila cuba lagi.';
            }
            ToastUtil.showError(context, errorMessage);
          }
        },
        builder: (context, state) {
          return Scaffold(
            resizeToAvoidBottomInset: true,
            body: state.status == UserStatus.loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                              const SizedBox(height: 40),
                              Text(
                                'Daily Quran',
                                style: TextStyle(
                                  letterSpacing: 2.0,
                                  fontFamily: 'Kahfi',
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 32),
                              TextField(
                                controller: emailController,
                                enabled: true, // Always enabled
                                decoration: const InputDecoration(
                                  labelText: 'Emel atau Telefon',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (value) {
                                  // Clear error state when user starts typing
                                  if (_lastErrorCode != null) {
                                    setState(() {
                                      _lastErrorCode = null;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: passwordController,
                                enabled: true, // Always enabled
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Kata Laluan',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 24),

                              const SizedBox(height: 16),

                              // Loading indicator
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  onPressed:
                                      (state.status == UserStatus.loading)
                                      ? null
                                      : () => _handleLogin(
                                          context,
                                          emailController.text.trim(),
                                          passwordController.text.trim(),
                                        ),
                                  child: const Text('Log Masuk'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Google Sign-In Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed:
                                      (state.status == UserStatus.loading)
                                      ? null
                                      : () {
                                          setState(() {
                                            _loginAttempted = true;
                                          });
                                          context
                                              .read<UserCubit>()
                                              .signInWithGoogle();
                                        },
                                  icon: Icon(
                                    Icons.g_mobiledata,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  label: Text(
                                    'Log masuk dengan Google',
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () =>
                                    _showPasswordResetDialog(context),
                                child: const Text('Lupa Kata Laluan?'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/signup',
                                    arguments:
                                        emailController.text.trim().isNotEmpty
                                        ? emailController.text.trim()
                                        : null,
                                  );
                                },
                                child: const Text('Tiada akaun? Daftar'),
                              ),
                              // Show prominent signup button if user-not-found error occurred
                              if (_lastErrorCode == 'user-not-found') ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/signup',
                                        arguments:
                                            _lastEmail ??
                                            emailController.text.trim(),
                                      );
                                    },
                                    icon: const Icon(Icons.person_add),
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
                              const SizedBox(
                                height: 40,
                              ), // Bottom padding for keyboard
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
