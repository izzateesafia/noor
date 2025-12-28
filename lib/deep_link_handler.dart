import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class DeepLinkHandler {
  static const String _scheme = 'noor';
  static const String _host = 'app';
  
  static StreamSubscription? _subscription;
  static bool _isInitialized = false;
  static BuildContext? _context;

  // Initialize deep link handling
  static Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    
    _context = context;
    
    try {
      final appLinks = AppLinks();
      
      // Handle initial link if app was opened via deep link
      final initialLink = await appLinks.getInitialAppLink();
      if (initialLink != null) {
        print('Initial deep link: $initialLink');
        _handleDeepLink(initialLink.toString());
      }

      // Listen for incoming links when app is already running
      _subscription = appLinks.uriLinkStream.listen((Uri uri) {
        print('Incoming deep link: ${uri.toString()}');
        _handleDeepLink(uri.toString());
      }, onError: (err) {
        print('Deep link error: $err');
      });

      _isInitialized = true;
      print('Deep link handler initialized successfully');
    } catch (e) {
      print('Failed to initialize deep links: $e');
    }
  }

  // Handle incoming deep links
  static void _handleDeepLink(String link) {
    try {
      print('Processing deep link: $link');
      final uri = Uri.parse(link);
      
      print('Parsed URI - Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
      
      // Check if it's our app's deep link
      if (uri.scheme == _scheme && uri.host == _host) {
        print('Valid deep link detected, navigating to: ${uri.path}');
        _navigateToPage(uri.path, uri.queryParameters);
      } else {
        print('Invalid deep link scheme or host: ${uri.scheme}://${uri.host}');
      }
    } catch (e) {
      print('Error parsing deep link: $e');
    }
  }

  // Navigate to specific page based on path
  static void _navigateToPage(String path, Map<String, String> queryParams) {
    if (_context == null) {
      print('Context is null, cannot navigate');
      return;
    }

    print('Navigating to path: $path');
    
    switch (path.toLowerCase()) {
      case '/premium':
      case '/subscription':
        print('Navigating to premium page');
        Navigator.of(_context!).pushNamed('/premium');
        break;
        
      case '/profile':
      case '/user':
        print('Navigating to profile page');
        Navigator.of(_context!).pushNamed('/profile');
        break;
        
      case '/classes':
      case '/courses':
        print('Navigating to classes page');
        Navigator.of(_context!).pushNamed('/classes');
        break;
        
      case '/duas':
      case '/prayers':
        print('Navigating to duas page');
        Navigator.of(_context!).pushNamed('/duas');
        break;
        
      case '/hadiths':
      case '/hadith':
        print('Navigating to hadiths page');
        Navigator.of(_context!).pushNamed('/hadiths');
        break;
        
      case '/qiblah':
      case '/qibla':
        print('Navigating to qiblah page');
        Navigator.of(_context!).pushNamed('/qiblah');
        break;
        
      case '/rukun':
      case '/prayer-steps':
        print('Navigating to rukun solat page');
        Navigator.of(_context!).pushNamed('/rukun_solat');
        break;
        
      case '/admin':
        print('Navigating to admin page');
        Navigator.of(_context!).pushNamed('/admin');
        break;
        
      case '/dashboard':
      case '/home':
      case '/':
        print('Navigating to dashboard page');
        Navigator.of(_context!).pushNamed('/dashboard');
        break;
        
      default:
        print('Unknown path: $path, defaulting to dashboard');
        Navigator.of(_context!).pushNamed('/dashboard');
        break;
    }
  }

  // Update context when it changes
  static void updateContext(BuildContext context) {
    _context = context;
  }

  // Generate deep link URL
  static String generateDeepLink(String path, {Map<String, String>? queryParams}) {
    final uri = Uri(
      scheme: _scheme,
      host: _host,
      path: path,
      queryParameters: queryParams,
    );
    return uri.toString();
  }

  // Generate specific deep links
  static String getPremiumLink() => generateDeepLink('/premium');
  static String getProfileLink() => generateDeepLink('/profile');
  static String getClassesLink() => generateDeepLink('/classes');
  static String getDuasLink() => generateDeepLink('/duas');
  static String getHadithsLink() => generateDeepLink('/hadiths');
  static String getQiblahLink() => generateDeepLink('/qiblah');
  static String getRukunLink() => generateDeepLink('/rukun');
  static String getDashboardLink() => generateDeepLink('/dashboard');

  // Dispose resources
  static void dispose() {
    _subscription?.cancel();
    _context = null;
    _isInitialized = false;
  }
}

// Deep link routes for easy access
class DeepLinkRoutes {
  static const String premium = 'noor://app/premium';
  static const String profile = 'noor://app/profile';
  static const String classes = 'noor://app/classes';
  static const String duas = 'noor://app/duas';
  static const String hadiths = 'noor://app/hadiths';
  static const String qiblah = 'noor://app/qiblah';
  static const String rukun = 'noor://app/rukun';
  static const String dashboard = 'noor://app/dashboard';
  static const String admin = 'noor://app/admin';
} 