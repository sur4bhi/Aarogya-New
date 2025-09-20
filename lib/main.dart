import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme.dart';
import 'core/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first2
  await Firebase.initializeApp(
    //options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aarogya Sahayak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        extensions: const [HealthColors.light],
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        extensions: const [HealthColors.dark],
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

