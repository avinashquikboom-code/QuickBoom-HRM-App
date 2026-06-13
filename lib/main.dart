import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/constants/app_theme.dart';
import 'core/services/notification_service.dart';
import 'views/splash/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service (non-blocking)
  NotificationService().initialize();
  
  // Print HR credentials to console for easy access
  debugPrint('🔐 HR MOBILE LOGIN CREDENTIALS:');
  debugPrint('═══════════════════════════════════════');
  debugPrint('📧 HR Email: hr@hrm.com');
  debugPrint('🔑 HR Password: 123456');
  debugPrint('👤 HR Name: Priya Sharma');
  debugPrint('═══════════════════════════════════════');
  debugPrint('📧 Employee Email: employee@hrm.com');
  debugPrint('🔑 Employee Password: employee123');
  debugPrint('👤 Employee Name: Rahul Verma');
  debugPrint('═══════════════════════════════════════');
  debugPrint('📧 Admin Email: admin@hr.com');
  debugPrint('🔑 Admin Password: 123456');
  debugPrint('👤 Admin Name: Super Admin');
  debugPrint('═══════════════════════════════════════');
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // or light depending on theme, we'll set dark by default
    ),
  );
  runApp(
    const ProviderScope(
      child: HrmApp(),
    ),
  );
}

class HrmApp extends StatelessWidget {
  const HrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashView(),
    );
  }
}
