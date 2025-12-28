import 'package:flutter/material.dart';
import 'repository/app_settings_repository.dart';

class WelcomeMessageScreen extends StatefulWidget {
  final String? userId;
  final bool hasCompletedBiodata;

  const WelcomeMessageScreen({
    super.key,
    this.userId,
    required this.hasCompletedBiodata,
  });

  @override
  State<WelcomeMessageScreen> createState() => _WelcomeMessageScreenState();
}

class _WelcomeMessageScreenState extends State<WelcomeMessageScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _welcomeMessage = 'Ready to level up your Quran recitation?';
  bool _isLoading = true;
  final AppSettingsRepository _appSettingsRepo = AppSettingsRepository();

  @override
  void initState() {
    super.initState();

    // Setup fade animation - repeat for continuous fade in/out
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 2 seconds for one fade cycle
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadWelcomeMessage();
  }

  Future<void> _loadWelcomeMessage() async {
    try {
      final message = await _appSettingsRepo.getWelcomeMessage();
      if (mounted) {
        setState(() {
          _welcomeMessage = message;
          _isLoading = false;
        });
        // Start continuous fade in/out animation
        _animationController.repeat(reverse: true);
        // After 5 seconds, navigate to dashboard
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _animationController.stop();
            _navigateToDashboard();
          }
        });
      }
    } catch (e) {
      print('Error loading welcome message: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Start continuous fade in/out animation even on error
        _animationController.repeat(reverse: true);
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _animationController.stop();
            _navigateToDashboard();
          }
        });
      }
    }
  }

  void _navigateToDashboard() {
    if (widget.hasCompletedBiodata) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/biodata');
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
        child: _isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : FadeTransition(
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
              ),
      ),
    );
  }
}

