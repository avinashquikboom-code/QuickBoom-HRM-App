import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_theme.dart';
import 'views/splash/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Print HR credentials to console for easy access
  print('🔐 HR MOBILE LOGIN CREDENTIALS:');
  print('═══════════════════════════════════════');
  print('📧 HR Email: hr@hrm.com');
  print('🔑 HR Password: 123456');
  print('👤 HR Name: Priya Sharma');
  print('═══════════════════════════════════════');
  print('📧 Employee Email: employee@hrm.com');
  print('🔑 Employee Password: employee123');
  print('👤 Employee Name: Rahul Verma');
  print('═══════════════════════════════════════');
  print('📧 Admin Email: admin@hr.com');
  print('🔑 Admin Password: 123456');
  print('👤 Admin Name: Super Admin');
  print('═══════════════════════════════════════');
  
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
