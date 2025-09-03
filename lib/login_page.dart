import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'main.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';
import 'repository/user_repository.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> _handleLogin(BuildContext context, String email, String password) async {
    try {
      await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      await saveUserToken();
      Navigator.pushReplacementNamed(context, '/role');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    }
  }

  Future<bool> _checkAndRequestLocationPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      bool shouldRequest = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Location Permission'),
          content: const Text('This app needs access to your location to provide Qiblah direction and other features.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Deny'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Allow'),
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
          title: const Text('Permission Required'),
          content: const Text('Location permission is permanently denied. Please enable it in your device settings.'),
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
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Enter your email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(emailController.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset email: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    
    return BlocProvider(
      create: (context) => UserCubit(UserRepository()),
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
              Navigator.pushReplacementNamed(context, '/role');
            }
          } else if (state.status == UserStatus.error) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error ?? 'An error occurred'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Login')),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Daily Quran',
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
                    decoration: InputDecoration(
                      labelText: 'Email or Phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                      child: state.status == UserStatus.loading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login'),
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
                        'Sign in with Google',
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
                    child: const Text('Forgot Password?'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text('Don\'t have an account? Sign Up'),
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