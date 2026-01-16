import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart'; // For API Key

class RecommendationScreen extends StatefulWidget {
  final String selectedStyle;

  const RecommendationScreen({
    super.key,
    required this.selectedStyle,
  });

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  File? _image;
  List<Map<String, dynamic>> _recommendations = [];
  String _errorMessage = "";
  bool _loading = false;

  Future<void> _pickAndAnalyze() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);

    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _loading = true;
      _errorMessage = "";
      _recommendations = [];
    });

    try {
      final model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
      final Uint8List imageBytes = await _image!.readAsBytes();

      final prompt = """
      Bir Pinterest moda danışmanı gibi bu kıyafeti analiz et. 
      '${widget.selectedStyle}' tarzına uygun olacak şekilde 3 adet tamamlayıcı parça öner.
      
      Yanıtını SADECE şu JSON listesi formatında ver:
      [
        {
          "parca_adi": "parça adı (kısa)",
          "aciklama": "neden bu kombine uygun olduğuna dair 1 cümlelik styling önerisi",
          "arama_terimi": "aesthetic flatlay outfit [piece_name] minimalist clothing"
        }
      ]
      
      KRİTİK KURALLAR:
      1. SADECE JSON döndür.
      2. 'arama_terimi' mutlaka İngilizce olmalı ve bir Pinterest flatlay çekimini yansıtacak terimler (outfit, flatlay, clothing) içermelidir. "fashion" kelimesini kullanma.
      """;

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ]);

      if (response.text != null) {
        String cleanedJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
        final List<dynamic> decoded = jsonDecode(cleanedJson);
        setState(() {
          _recommendations = List<Map<String, dynamic>>.from(decoded);
        });
      } else {
         setState(() {
          _errorMessage = "Öneri bulunamadı.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Hata oluştu: $e";
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.selectedStyle} Analizi")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAndAnalyze,
              child: Container(
                width: double.infinity,
                height: 400,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black12),
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo, size: 60, color: Colors.grey),
                          const SizedBox(height: 15),
                          Text(
                            "FOTOĞRAF YÜKLE",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(letterSpacing: 2),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 30),
            if (_loading) const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 20),
            if (_recommendations.isNotEmpty) ...[
              for (var recipient in _recommendations)
                Container(
                  margin: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          'https://loremflickr.com/600/800/${Uri.encodeComponent((recipient['arama_terimi'] ?? recipient['parca_adi'] ?? 'outfit').replaceAll(' ', ','))}/all?lock=${(recipient['parca_adi'] ?? 'style').hashCode}',
                          height: 350,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, __) => Container(
                            height: 350,
                            color: const Color(0xFFF2F2F7),
                            child: const Center(child: Icon(Icons.broken_image, color: Colors.black12)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipient['parca_adi']?.toUpperCase() ?? '',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontSize: 22,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              recipient['aciklama'] ?? '',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                                color: const Color(0xFF3C3C43),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () async {
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user == null) return;

                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('favorites')
                                      .add({
                                    'parca_adi': recipient['parca_adi'],
                                    'aciklama': recipient['aciklama'],
                                    'arama_terimi': recipient['arama_terimi'] ?? recipient['parca_adi'],
                                    'timestamp': FieldValue.serverTimestamp(),
                                  });

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Gardırobuna eklendi!")),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                                label: const Text("KAYDET", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.black12),
                    ],
                  ),
                ),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12),
                ),
                child: Text(
                  _errorMessage.isNotEmpty ? _errorMessage : "Fotoğraf yükleyin ve yapay zeka stilinizi analiz etsin.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
