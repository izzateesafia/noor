import 'package:daily_quran/qibla_compass.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'role_selection_page.dart';
import 'dashboard/dashboard_page.dart';
import 'theme_constants.dart';
import 'theme.dart';
import 'duas_page.dart';
import 'hifdh_checker_page.dart';
import 'admin_page.dart';
import 'classes_page.dart';
import 'hadiths_page.dart';
import 'rukun_solat_page.dart';
import 'premium_page.dart';
import 'class_enrollment_page.dart';
import 'user_profile_page.dart';
import 'biodata_page.dart';
import 'deep_link_handler.dart';
import 'deep_link_test_page.dart';
import 'quran_reader_page.dart';
import 'quran_search_page.dart';
import 'mushaf_reader_page.dart';
import 'prayer_alarm_settings_page.dart';
import 'services/prayer_alarm_service.dart';
import 'test_prayer_alarm.dart';
import 'cubit/user_cubit.dart';
import 'cubit/class_cubit.dart';
import 'cubit/dua_cubit.dart';
import 'cubit/hadith_cubit.dart';
import 'cubit/prayer_times_cubit.dart';
import 'cubit/prayer_times_states.dart';
import 'cubit/live_stream_cubit.dart';
import 'cubit/daily_tracker_cubit.dart';
import 'repository/user_repository.dart';
import 'repository/class_repository.dart';
import 'repository/dua_repository.dart';
import 'repository/hadith_repository.dart';
import 'repository/prayer_times_repository.dart';
import 'repository/live_stream_repository.dart';
import 'repository/daily_tracker_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;


final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await setupNotifications();
  await saveUserToken();
  
  // Initialize prayer alarm service
  await PrayerAlarmService().initialize();
  
  runApp(const MyApp());
}

Future<void> setupNotifications() async {
  // Request notification permissions
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // Create notification channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> saveUserToken() async {
  final user = firebase_auth.FirebaseAuth.instance.currentUser;
  if (user == null) return; // Only save if user is logged in
  
  try {
    if (Platform.isIOS) {
      // For iOS, we need to ensure APNS token is available first
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      
      if (apnsToken != null) {
        // APNS token is available, proceed to get FCM token
        await _saveFCMToken(user);
      } else {
        // APNS token not available yet, wait and retry
        print('APNS token not available, waiting 3 seconds and retrying...');
        await Future.delayed(const Duration(seconds: 3));
        
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          await _saveFCMToken(user);
        } else {
          print('APNS token still not available after retry');
        }
      }
    } else {
      // For Android, proceed directly
      await _saveFCMToken(user);
    }
  } catch (e) {
    print('Could not get FCM token: $e');
  }
  
  // Listen for token refreshes
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    try {
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('user_tokens')
            .doc(user.uid)
            .set({
          'token': newToken,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        });
        print('FCM token refreshed and saved');
      }
    } catch (e) {
      print('Could not update FCM token: $e');
    }
  });
}

Future<void> _saveFCMToken(firebase_auth.User user) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await FirebaseFirestore.instance
        .collection('user_tokens')
        .doc(user.uid)
        .set({
      'token': token,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
    print('FCM token saved successfully');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider<UserRepository>(
              create: (context) => UserRepository(),
            ),
            RepositoryProvider<ClassRepository>(
              create: (context) => ClassRepository(),
            ),
            RepositoryProvider<DuaRepository>(
              create: (context) => DuaRepository(),
            ),
            RepositoryProvider<HadithRepository>(
              create: (context) => HadithRepository(),
            ),
            RepositoryProvider<PrayerTimesRepository>(
              create: (context) => PrayerTimesRepository(),
            ),
            RepositoryProvider<LiveStreamRepository>(
              create: (context) => LiveStreamRepository(),
            ),
            RepositoryProvider<DailyTrackerRepository>(
              create: (context) => DailyTrackerRepository(),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<UserCubit>(
                create: (context) => UserCubit(
                  context.read<UserRepository>(),
                ),
              ),
              BlocProvider<ClassCubit>(
                create: (context) => ClassCubit(
                  context.read<ClassRepository>(),
                ),
              ),
              BlocProvider<DuaCubit>(
                create: (context) => DuaCubit(
                  context.read<DuaRepository>(),
                ),
              ),
              BlocProvider<HadithCubit>(
                create: (context) => HadithCubit(
                  context.read<HadithRepository>(),
                ),
              ),
              BlocProvider<PrayerTimesCubit>(
                create: (context) => PrayerTimesCubit(
                  context.read<PrayerTimesRepository>(),
                ),
              ),
              BlocProvider<LiveStreamCubit>(
                create: (context) => LiveStreamCubit(
                  context.read<LiveStreamRepository>(),
                ),
              ),
              BlocProvider<DailyTrackerCubit>(
                create: (context) => DailyTrackerCubit(
                  context.read<DailyTrackerRepository>(),
                ),
              ),
            ],
            child: MaterialApp(
              title: 'Daily Quran Onboarding',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: mode,
              initialRoute: '/',
              routes: {
                '/': (context) => const SplashScreen(),
                '/login': (context) => const LoginPage(),
                '/signup': (context) => const SignupPage(),
                '/role': (context) => const RoleSelectionPage(),
                '/dashboard': (context) => const DashboardPage(),
                '/duas': (context) => const DuasPage(),
                '/hifdh_checker': (context) => const HifdhCheckerPage(),
                '/admin': (context) => const AdminPage(),
                '/classes': (context) => const ClassesPage(),
                '/hadiths': (context) => const HadithsPage(),
                '/rukun_solat': (context) => const RukunSolatPage(),
                '/premium': (context) => const PremiumPage(),
                '/enroll_class': (context) => const ClassEnrollmentPage(),
                '/profile': (context) => const UserProfilePage(),
                '/biodata': (context) => const BiodataPage(),
                '/deep_link_test': (context) => const DeepLinkTestPage(),
                '/qiblah': (context) => const QiblaCompass(),
                '/quran': (context) => const QuranReaderPage(),
                '/quran_search': (context) => const QuranSearchPage(),
                '/mushaf': (context) => const MushafReaderPage(),
                '/prayer_alarm_settings': (context) => const PrayerAlarmSettingsPage(),
                '/test_prayer_alarm': (context) => const TestPrayerAlarmPage(),
              },
              builder: (context, child) {
                // Initialize deep links with proper context
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  DeepLinkHandler.initialize(context);
                });
                return child!;
              },
            ),
          ),
        );
      },
    );
  }
}

// SplashScreen

