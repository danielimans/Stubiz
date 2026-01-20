import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const StuBizApp());
}

class StuBizApp extends StatelessWidget {
  const StuBizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StuBiz',
      theme: ThemeData(useMaterial3: true),
      home: const SplashScreen(),
    );
  }
} 
