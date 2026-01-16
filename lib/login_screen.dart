import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moda_asistani/main_shell.dart';
import 'package:moda_asistani/register_screen.dart';
import 'package:moda_asistani/gender_selection_screen.dart';

// 🔑 API KEY
const String apiKey = 'api key';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen e-posta ve şifrenizi girin.")),
      );
      return;
    }
    
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => GenderSelectionScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Bir hata oluştu.";
      switch (e.code) {
        case "user-not-found":
          errorMessage = "Kullanıcı bulunamadı.";
          break;
        case "wrong-password":
          errorMessage = "Şifre hatalı.";
          break;
        default:
          errorMessage = "Hata: ${e.message}";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Integrated Logo Brand Block
              const SizedBox(height: 40),
              Image.asset(
                'assets/images/logo.png',
                height: 220,
                width: 220,
                fit: BoxFit.contain,
                errorBuilder: (ctx, _, __) => const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.black12),
              ),
              const SizedBox(height: 12),
              const Text(
                "PREMIUM FASHION ECOSYSTEM",
                style: TextStyle(
                  letterSpacing: 4,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black26,
                ),
              ),
              
              const SizedBox(height: 80),
              
              // Minimalist Enriched Inputs
              TextField(
                controller: _emailController,
                style: const TextStyle(fontSize: 14, letterSpacing: 0.5),
                decoration: InputDecoration(
                  labelText: "E-POSTA",
                  labelStyle: const TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900, color: Colors.black54),
                  hintText: "example@vestis.one",
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.1), fontSize: 13),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFEEEEEE))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(fontSize: 14, letterSpacing: 2),
                decoration: InputDecoration(
                  labelText: "ŞİFRE",
                  labelStyle: const TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900, color: Colors.black54),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFEEEEEE))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Signature Vestis Button
              if (_loading)
                const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
              else
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "DENEYİME BAŞLA",
                      style: TextStyle(
                        letterSpacing: 3,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                    
              const SizedBox(height: 40),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black38, fontSize: 11, letterSpacing: 1),
                    children: [
                      TextSpan(text: "HESABIN YOK MU? "),
                      TextSpan(
                        text: "KAYDOL",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
