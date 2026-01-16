import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moda_asistani/gender_selection_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => GenderSelectionScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kayıt hatası: ${e.message}"), backgroundColor: Colors.redAccent),
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
      appBar: AppBar(
        elevation: 0, 
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black, size: 20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              // Integrated Logo Brand Block
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/logo.png',
                height: 180,
                width: 180,
                fit: BoxFit.contain,
                errorBuilder: (ctx, _, __) => const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.black12),
              ),
              const SizedBox(height: 12),
              const Text(
                "YENİ HESAP OLUŞTUR",
                style: TextStyle(
                  letterSpacing: 2, 
                  fontSize: 10, 
                  color: Colors.black26, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Minimalist Enriched Inputs
              TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14, letterSpacing: 0.5),
                decoration: const InputDecoration(
                  labelText: "AD SOYAD",
                  labelStyle: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w900, color: Colors.black54),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFEEEEEE))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                style: const TextStyle(fontSize: 14, letterSpacing: 0.5),
                decoration: const InputDecoration(
                  labelText: "E-POSTA",
                  labelStyle: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w900, color: Colors.black54),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFEEEEEE))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(fontSize: 14, letterSpacing: 2),
                decoration: const InputDecoration(
                  labelText: "ŞİFRE",
                  labelStyle: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w900, color: Colors.black54),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFEEEEEE))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              
              const SizedBox(height: 50),
              
              if (_loading)
                const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
              else
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "KAYIT OL VE KEŞFET",
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12),
                    ),
                  ),
                ),
                    
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "ZATEN HESABIN VAR MI? GİRİŞ YAP",
                  style: TextStyle(
                    fontSize: 11, 
                    decoration: TextDecoration.underline, 
                    color: Colors.black45,
                    letterSpacing: 0.5,
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
