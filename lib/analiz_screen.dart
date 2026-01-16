import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart'; // For API Key

class AnalizScreen extends StatefulWidget {
  final String? tarz;
  final String? gender;
  final String? weatherInfo;
  final File? initialImage;
  const AnalizScreen({
    super.key,
    this.tarz,
    this.gender,
    this.weatherInfo,
    this.initialImage,
  });

  @override
  State<AnalizScreen> createState() => _AnalizScreenState();
}

class _AnalizScreenState extends State<AnalizScreen> {
  List<File> _inputImages = [];
  bool _loading = false;
  List<Map<String, dynamic>> _recommendations = [];
  String _errorMessage = "";
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
    if (widget.initialImage != null) {
      _inputImages = [widget.initialImage!];
      _analyzeImage();
    }
  }

  Future<void> _fetchFavorites() async {
    // Currently not used for UI state in the new flow, but kept for future checkmarks if needed.
    // In the new flow, we just let the user heart items.
  }

  Future<String?> _uploadToStorage(File file, String folder) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final fileName = "${folder}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = FirebaseStorage.instance.ref().child('users/${user.uid}/$folder/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Storage error: $e");
      return null;
    }
  }


  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final List<XFile> pickedList = await picker.pickMultiImage(maxWidth: 1000);
      if (pickedList.isNotEmpty) {
        setState(() {
          _inputImages = pickedList.map((x) => File(x.path)).toList();
          _analyzeImage();
        });
      }
    } else {
      final XFile? picked = await picker.pickImage(source: source, maxWidth: 1000);
      if (picked != null) {
        setState(() {
          _inputImages = [File(picked.path)];
          _analyzeImage();
        });
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_inputImages.isEmpty) return;
    setState(() {
      _loading = true;
      _showResults = true;
      _errorMessage = "";
      _recommendations = [];
    });

    try {
      final model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
      
      final List<DataPart> imageParts = [];
      for (var imgFile in _inputImages) {
        final Uint8List bytes = await imgFile.readAsBytes();
        imageParts.add(DataPart('image/jpeg', bytes));
      }

      final prompt = """
      Kullanıcının yüklediği bu gardırop parçalarına (bir veya birden fazla olabilir) uygun lüks ve modern bir kombin oluştur. 
      Bu parçaları tamamlayacak ve hepsiyle uyum sağlayacak 3 farklı ürün öner ve bu parçanın genel stil puanını (0-100) belirle.
      Yanıtı SADECE şu JSON formatında ver:
      {"style_score": 85, "oneriler": [{"parca_adi": "ad", "aciklama": "neden uygun", "arama_terimi": "aesthetic Pinterest style flatlay [item name] minimalist luxury clothing"}]}
      Önemli: arama_terimi mutlaka İngilizce olmalı ve bir Pinterest flatlay çekimini yansıtacak detayda olmalıdır.
      """;

      final response = await model.generateContent([
        Content.multi([TextPart(prompt), ...imageParts])
      ]);

      if (response.text != null) {
        String cleanedJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
        final decoded = jsonDecode(cleanedJson);
        setState(() {
          _recommendations = List<Map<String, dynamic>>.from(decoded['oneriler']);
        });

        // Analizi Firestore'a kaydet
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Birden fazla resim varsa ilkini veya birleştirilmiş bir şeyi kaydedebiliriz.
          // Şimdilik sadece ilk resmi kaydedelim veya hepsini url listesi yapabiliriz.
          // Basitlik için ilkini kaydediyoruz.
          final imageUrl = await _uploadToStorage(_inputImages.first, 'analyses');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('analyses')
              .add({
            'style_score': decoded['style_score'] ?? 0,
            'img_url': imageUrl,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "Hata: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .add({
        'parca_adi': item['parca_adi'],
        'aciklama': item['aciklama'],
        'arama_terimi': item['arama_terimi'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${item['parca_adi']} favorilere eklendi!")),
        );
      }
    } catch (e) {
      debugPrint("Favori hatası: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_showResults) return _buildResultView();
    return _buildStudioView();
  }

  Widget _buildStudioView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text("GARDIROBUM", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_enhance_outlined, size: 100, color: Colors.black12),
              const SizedBox(height: 30),
              const Text(
                "STİLİNİZİ OLUŞTURUN",
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Bir kıyafetinizin fotoğrafını çekin veya seçin, AI sizin için en şık kombin parçalarını önersin.",
                style: TextStyle(color: Colors.black38, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              _buildActionButton(
                icon: Icons.camera_alt,
                label: "FOTOĞRAF ÇEK",
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                icon: Icons.photo_library,
                label: "GALERİDEN SEÇ",
                onTap: () => _pickImage(ImageSource.gallery),
                isOutline: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, bool isOutline = false}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: isOutline 
        ? OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 20),
            label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 20, color: Colors.white),
            label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
          ),
    );
  }

  Widget _buildResultView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(onPressed: () => setState(() => _showResults = false)),
        actions: [
          IconButton(
            onPressed: _analyzeImage,
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black)) 
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_inputImages.isNotEmpty)
                  SizedBox(
                    height: 250,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _inputImages.length,
                      separatorBuilder: (c, i) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => Container(
                        width: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(image: FileImage(_inputImages[i]), fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                const Text(
                  "ÖNERİLEN KOMBİN",
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Colors.black38),
                ),
                const SizedBox(height: 20),
                if (_errorMessage.isNotEmpty) 
                  Text(_errorMessage) 
                else 
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recommendations.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 30),
                    itemBuilder: (context, i) => _buildRecommendationItem(_recommendations[i], i),
                  ),
                const SizedBox(height: 50),
              ],
            ),
          ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> item, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                'https://loremflickr.com/800/1000/fashion,outfit,${Uri.encodeComponent(item['arama_terimi'] ?? 'outfit')}/all?lock=${item['parca_adi'].hashCode}',
                height: 400,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(height: 400, color: const Color(0xFFF2F2F7), child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black12)));
                },
              ),
            ),
            Positioned(
              top: 15,
              right: 15,
              child: FloatingActionButton.small(
                onPressed: () => _toggleFavorite(item),
                backgroundColor: Colors.white.withOpacity(0.9),
                child: const Icon(Icons.favorite_border, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          item['parca_adi']?.toUpperCase() ?? '',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Text(
          item['aciklama'] ?? '',
          style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

}
