import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';
import 'repository/user_repository.dart';
import 'models/user_model.dart';
import 'repository/app_settings_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _welcomeMessage = 'Ready to level up your Quran recitation?';
  bool _showWelcomeMessage = true; // Show message immediately
  final AppSettingsRepository _appSettingsRepo = AppSettingsRepository();

  @override
  void initState() {
    super.initState();
    
    // Setup fade animation - total duration: 1s fade in + 2s hold + 1s fade out = 4s
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Create a sequence: fade in (0-1s), hold (1-3s), fade out (3-4s)
    _fadeAnimation = TweenSequence<double>([
      // Fade in: 0 to 1 over first 1 second
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1.0, // 25% of total duration (1s out of 4s)
      ),
      // Hold: stay at 1.0 for 2 seconds
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 2.0, // 50% of total duration (2s out of 4s)
      ),
      // Fade out: 1 to 0 over last 1 second
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1.0, // 25% of total duration (1s out of 4s)
      ),
    ]).animate(_animationController);

    // Start animation immediately
    _animationController.forward();
    
    // Load custom message in background and update if available
    _loadWelcomeMessageAndCheckAuth();
  }

  Future<void> _loadWelcomeMessageAndCheckAuth() async {
    // Load custom welcome message in background (non-blocking)
    // If it loads quickly, update the message; otherwise use default
    _appSettingsRepo.getWelcomeMessage().then((message) {
      if (mounted && _animationController.value < 0.5) {
        // Only update if animation hasn't progressed too far (still in fade in or early hold phase)
        setState(() {
          _welcomeMessage = message;
        });
      }
    }).catchError((e) {
      // Keep default message if loading fails
    });

    // Wait for animation to complete (4 seconds: 1s fade in + 2s hold + 1s fade out)
    await Future.delayed(const Duration(milliseconds: 4000));
    
    if (!mounted) return;
    
    // Now check auth and navigate
    await _checkAuthStatus();
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
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      // On error, go to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _showWelcomeMessage
            ? FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _welcomeMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
} 