import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'main.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';
import 'repository/user_repository.dart';
import 'services/google_auth_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> _handleLogin(BuildContext context, String email, String password) async {
    try {
      await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      await saveUserToken();
      Navigator.pushReplacementNamed(context, '/role');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Log masuk gagal: ${e.toString()}')),
      );
    }
  }

  Future<bool> _checkAndRequestLocationPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      bool shouldRequest = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Kebenaran Lokasi'),
          content: const Text('Aplikasi ini memerlukan akses ke lokasi anda untuk memberikan arah Qiblah dan ciri-ciri lain.'),
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
          content: const Text('Kebenaran lokasi telah ditolak secara kekal. Sila aktifkan dalam tetapan peranti anda.'),
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
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
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
        await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emel set semula kata laluan telah dihantar!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghantar emel set semula: ${e.toString()}')),
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
            print('Auto-resetting stuck loading state');
            cubit.resetState();
          }
        });
        
        return cubit;
      },
      child: BlocConsumer<UserCubit, UserState>(
        listener: (context, state) {
          if (state.status == UserStatus.loaded && state.currentUser != null) {
            final user = state.currentUser!;
            
            // Check if user needs to complete biodata
            if (!user.hasCompletedBiodata) {
              // Navigate to biodata page for first-time users
              Navigator.pushReplacementNamed(context, '/biodata', arguments: user);
            } else {
              // User has completed biodata, navigate to role selection
              Navigator.pushReplacementNamed(context, '/main');
            }
          }
          // Removed error snackbar - it was showing annoying messages on page load
        },
        builder: (context, state) {
          return Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60), // Add top spacing since no AppBar
                  Text(
                    'Al-Quran Harian',
                    style: TextStyle(
                      letterSpacing: 2.0,
                      fontFamily: 'Kahfi',
                      color: Colors.red.shade900,
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: emailController,
                    enabled: true, // Always enabled
                    decoration: InputDecoration(
                      labelText: 'Emel atau Telefon',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    enabled: true, // Always enabled
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Kata Laluan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Loading indicator
                  if (state.status == UserStatus.loading)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sedang memproses...',
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: state.status == UserStatus.loading 
                        ? null 
                        : () => _handleLogin(context, emailController.text.trim(), passwordController.text.trim()),
                      child: const Text('Log Masuk'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Google Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: state.status == UserStatus.loading 
                        ? null 
                        : () => context.read<UserCubit>().signInWithGoogle(),
                      icon: Icon(
                        Icons.g_mobiledata,
                        color: Colors.red.shade700,
                        size: 24,
                      ),
                      label: Text(
                        'Log masuk dengan Google',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _showPasswordResetDialog(context),
                    child: const Text('Lupa Kata Laluan?'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text('Tiada akaun? Daftar'),
                  ),
                  const SizedBox(height: 16),
                  // Debug buttons
                  if (state.status == UserStatus.loading)
                    TextButton(
                      onPressed: () {
                        context.read<UserCubit>().resetState();
                      },
                      child: const Text('Reset (Debug)'),
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