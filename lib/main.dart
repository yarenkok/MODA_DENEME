import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'package:moda_asistani/login_screen.dart';
import 'package:moda_asistani/main_shell.dart';
import 'package:moda_asistani/gender_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VESTIS ONE',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF000000),
          primary: const Color(0xFF000000), // Pure Noir
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(
          const TextTheme(
            displayLarge: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF000000), fontSize: 32, letterSpacing: -1.2),
            displayMedium: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF000000), fontSize: 24, letterSpacing: -0.8),
            displaySmall: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF000000), fontSize: 20, letterSpacing: -0.5),
            bodyLarge: TextStyle(color: Color(0xFF000000), fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
            bodyMedium: TextStyle(color: Color(0xFF8E8E93), fontSize: 14, height: 1.4),
            labelLarge: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Color(0xFF000000), fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          iconTheme: IconThemeData(color: Color(0xFF000000), size: 22),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF2F2F7),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF000000), width: 1.5),
          ),
          hintStyle: const TextStyle(color: Color(0xFFBCBCC0), fontWeight: FontWeight.w500),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF000000),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 20),
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 14),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF000000),
          size: 24,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return GenderSelectionScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}