import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'blocs/payment/payment_bloc.dart';
import 'splash_screen.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'role_selection_page.dart';
import 'dashboard/dashboard_page.dart';
import 'main_navigation_page.dart';
import 'menu_page.dart';
import 'theme_constants.dart';
import 'theme.dart';
import 'duas_page.dart';
import 'admin_page.dart';
import 'classes_page.dart';
import 'hadiths_page.dart';
import 'rukun_solat_page.dart';
import 'premium_page.dart';
import 'class_enrollment_page.dart';
import 'user_profile_page.dart';
import 'biodata_page.dart';
import 'card_info_page.dart';
import 'policy_page.dart';
import 'welcome_message_screen.dart';
import 'deep_link_handler.dart';
import 'deep_link_test_page.dart';
import 'quran_reader_page.dart';
import 'quran_search_page.dart';
import 'videos_page.dart';
import 'all_videos_page.dart';
import 'mushaf_reader_page.dart';
import 'pages/mushaf_selection_page.dart';
import 'pages/pdf_mushaf_viewer_page.dart';
import 'models/mushaf_model.dart';
import 'prayer_alarm_settings_page.dart';
import 'services/scheduled_alarm_service.dart';
import 'services/alarm_service.dart';
import 'services/lock_screen_notification_service.dart';
import 'test_prayer_alarm.dart';
// import 'adhan_tester_page.dart';
import 'qibla_compass.dart';
import 'test_simple_alarm.dart';
import 'test_scheduled_alarm.dart';
import 'ios_setup_guide_page.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';
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
import 'repository/news_repository.dart';
import 'cubit/news_cubit.dart';
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
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await setupNotifications();
  await saveUserToken();
  
  // Initialize scheduled alarm service
  await ScheduledAlarmService().initialize();
  
  // Initialize alarm service
  await AlarmService().initialize();
  
  // Initialize lock screen notification service
  await LockScreenNotificationService().initialize();
  
  // Initialize Stripe from environment variables
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  Stripe.merchantIdentifier = dotenv.env['STRIPE_MERCHANT_IDENTIFIER'] ?? 'merchant.com.hexahelix.dq';
  
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
    'Notifikasi Kepentingan Tinggi',
    description: 'Saluran ini digunakan untuk notifikasi penting.',
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
        await Future.delayed(const Duration(seconds: 3));
        
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          await _saveFCMToken(user);
        } else {
        }
      }
    } else {
      // For Android, proceed directly
      await _saveFCMToken(user);
    }
  } catch (e) {
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
      }
    } catch (e) {
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
            RepositoryProvider<NewsRepository>(
              create: (context) => NewsRepository(),
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
              BlocProvider<PaymentBloc>(
                create: (context) => PaymentBloc(),
              ),
              BlocProvider<NewsCubit>(
                create: (context) => NewsCubit(
                  context.read<NewsRepository>(),
                ),
              ),
            ],
            child: MaterialApp(
              title: 'Daily Quran',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: mode,
              initialRoute: '/',
              routes: {
                '/': (context) => const SplashScreen(),
                '/login': (context) => const LoginPage(),
                '/signup': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments;
                  return SignupPage(
                    preFilledEmail: args is String ? args : null,
                  );
                },
                '/role': (context) => const RoleSelectionPage(),
                '/dashboard': (context) => const MainNavigationPage(),
                '/main': (context) => const MainNavigationPage(),
                '/duas': (context) => const DuasPage(),
                '/admin': (context) => const AdminPage(),
                '/classes': (context) => const ClassesPage(),
                '/hadiths': (context) => const HadithsPage(),
                '/rukun_solat': (context) => BlocBuilder<UserCubit, UserState>(
                  builder: (context, state) {
                    return RukunSolatPage(
                      isPremium: state.currentUser?.isPremium ?? false,
                    );
                  },
                ),
                '/premium': (context) => const PremiumPage(),
                '/enroll_class': (context) => const ClassEnrollmentPage(),
                '/profile': (context) => const UserProfilePage(),
                '/biodata': (context) => const BiodataPage(),
                '/card-info': (context) => const CardInfoPage(),
                '/policy': (context) => const PolicyPage(),
                '/welcome': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                  return WelcomeMessageScreen(
                    userId: args?['userId'] as String?,
                    hasCompletedBiodata: args?['hasCompletedBiodata'] as bool? ?? false,
                  );
                },
                '/deep_link_test': (context) => const DeepLinkTestPage(),
                '/quran': (context) => const QuranReaderPage(),
                '/quran_search': (context) => const QuranSearchPage(),
                '/videos': (context) => const VideosPage(),
                '/all_videos': (context) => const AllVideosPage(),
                '/mushaf': (context) => const MushafReaderPage(),
                '/mushaf_pdf_selection': (context) => const MushafSelectionPage(),
                '/mushaf_pdf_viewer': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments;
                  if (args != null && args is MushafModel) {
                    return PDFMushafViewerPage(mushaf: args);
                  }
                  // Fallback - should not happen if navigation is correct
                  return const Scaffold(
                    body: Center(child: Text('Mushaf not provided')),
                  );
                },
                '/qiblah': (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Kompas Qibla'),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Theme.of(context).primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  ),
                  body: const QiblaCompass(),
                ),
                '/prayer_alarm_settings': (context) => const PrayerAlarmSettingsPage(),
                '/test_prayer_alarm': (context) => const TestPrayerAlarmPage(),
                // '/adhan_tester': (context) => const AdhanTesterPage(),
        '/test_simple_alarm': (context) => const TestSimpleAlarmPage(),
        '/test_scheduled_alarm': (context) => const TestScheduledAlarmPage(),
                '/ios_setup_guide': (context) => const IOSSetupGuidePage(),
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

