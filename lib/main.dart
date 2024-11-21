import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:loginpage/features/app/splash_screen/splash_screen.dart';
import 'package:loginpage/features/user_auth/presentation/pages/home_page.dart';
import 'package:loginpage/features/user_auth/presentation/pages/admin_home.dart';
import 'package:loginpage/features/user_auth/presentation/pages/login_page.dart';
import 'package:loginpage/features/user_auth/presentation/pages/sign_up_page.dart';
import 'package:loginpage/features/user_auth/presentation/pages/admin_login_page.dart';
import 'package:loginpage/features/user_auth/presentation/pages/AnnouncementPage.dart';
import 'package:loginpage/features/user_auth/presentation/pages/ComplaintPage.dart';
import 'package:loginpage/features/user_auth/presentation/pages/FileComplaintPage.dart';
import 'package:loginpage/features/user_auth/presentation/pages/AdComplaintPage.dart';
import 'package:loginpage/features/user_auth/presentation/pages/UpdateAnnouncementsPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCzxzH1UHWVonvgID6NIbwVxN1EV3J4Mr4",
      appId: "1:722788071130:web:c7cf682fbf701eaff8d7e3",
      messagingSenderId: "722788071130",
      projectId: "flutter-firebase-8eb80",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aquapulse',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/signUp': (context) => const SignUpPage(),
        '/home': (context) => HomePage(),
        '/admin_home': (context) => AdminHomePage(),
        '/adminLogin': (context) => const AdminLoginPage(),
        '/announcement': (context) => const AnnouncementPage(),
        '/complaint': (context) => ComplaintPage(),
        '/file_complaint': (context) => const FileComplaintPage(),
        '/updateAnnouncements': (context) => const UpdateAnnouncementsPage(),
        '/complaints': (context) => const ComplaintsPage(),
      },
    );
  }
}
