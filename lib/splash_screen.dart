import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';
import 'repository/user_repository.dart';
import 'models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for splash screen to show for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    try {
      // Check if user is already authenticated
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // User is authenticated, fetch user data and navigate to appropriate page
        print('User already authenticated: ${currentUser.uid}');
        
        // Create a temporary UserCubit to fetch user data
        final userCubit = UserCubit(UserRepository());
        await userCubit.fetchCurrentUser();
        
        if (mounted) {
          if (userCubit.state.status == UserStatus.loaded && userCubit.state.currentUser != null) {
            final user = userCubit.state.currentUser!;
            
            // Check if user needs to complete biodata
            if (!user.hasCompletedBiodata) {
              Navigator.pushReplacementNamed(context, '/biodata', arguments: user);
            } else {
              // User is fully set up, go to main navigation
              Navigator.pushReplacementNamed(context, '/main');
            }
          } else {
            // User data not found, go to login
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      } else {
        // No authenticated user, go to login
        print('No authenticated user found');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print('Error checking auth status: $e');
      // On error, go to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flash_on, size: 100, color: Colors.red.shade900),
            const SizedBox(height: 24),
            Text(
              'Daily Quran',
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: const Text(
                  'Teman harian untuk menjadi Muslim yang lebih baik',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 