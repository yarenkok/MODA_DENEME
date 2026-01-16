import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moda_asistani/login_screen.dart';
import 'package:moda_asistani/main_shell.dart';

class GenderSelectionScreen extends StatelessWidget {
  const GenderSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Merhaba, ${FirebaseAuth.instance.currentUser?.displayName ?? 'Moda Sever'}",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              "Kimin için stil arıyoruz?",
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGenderCard(context, "Kadın", Icons.female, Colors.pinkAccent),
                const SizedBox(width: 30),
                _buildGenderCard(context, "Erkek", Icons.male, Colors.blueAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderCard(BuildContext context, String gender, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainShell(gender: gender),
          ),
        );
      },
      child: Container(
        width: 150,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, spreadRadius: 0, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 70, color: color.withOpacity(0.8)),
            const SizedBox(height: 15),
            Text(
              gender.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
            )
          ],
        ),
      ),
    );
  }
}
